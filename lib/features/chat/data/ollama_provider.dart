import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../domain/llm_provider.dart';
import '../domain/llm_settings.dart';

class OllamaException implements Exception {
  const OllamaException(this.failure);
  final LlmFailure failure;
}

class OllamaService {
  OllamaService({
    Uri? endpoint,
    this.responseTimeout = const Duration(seconds: 90),
  }) : endpoint = endpoint ?? Uri.parse('http://127.0.0.1:11434') {
    if (this.endpoint.scheme != 'http' ||
        !['127.0.0.1', '::1'].contains(this.endpoint.host) ||
        this.endpoint.userInfo.isNotEmpty ||
        this.endpoint.path.isNotEmpty && this.endpoint.path != '/') {
      throw ArgumentError(
        'Only explicit loopback Ollama addresses are supported.',
      );
    }
  }
  final Uri endpoint;
  final Duration responseTimeout;
  bool _busy = false;
  HttpClient? _active;
  Completer<void>? _finished;
  Future<void> abortAndWait() async {
    close();
    await _finished?.future.timeout(const Duration(seconds: 5));
  }

  void close() => _active?.close(force: true);
  HttpClient _client() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..findProxy = (_) => 'DIRECT';
  Stream<List<int>> _bounded(Stream<List<int>> input) async* {
    var bytes = 0;
    await for (final chunk in input) {
      bytes += chunk.length;
      if (bytes > 1024 * 1024) {
        throw const FormatException('Oversized response');
      }
      yield chunk;
    }
  }

  Future<Map<String, dynamic>> json(
    String path, {
    Map<String, Object?>? body,
  }) async {
    final client = _client();
    try {
      final request = await (body == null
          ? client.getUrl(endpoint.resolve(path))
          : client.postUrl(endpoint.resolve(path)));
      request.followRedirects = false;
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) {
        throw const OllamaException(
          LlmFailure(
            LlmErrorCode.requestFailed,
            'Ollama request failed. Check ollama ps and retry.',
          ),
        );
      }
      final data = await utf8.decoder
          .bind(_bounded(response))
          .join()
          .timeout(const Duration(seconds: 5));
      if (data.length > 1024 * 1024) {
        throw const FormatException('Oversized response');
      }
      return jsonDecode(data) as Map<String, dynamic>;
    } on SocketException {
      throw const OllamaException(
        LlmFailure(
          LlmErrorCode.unavailable,
          'Ollama is not installed or not running. If installed, run: ollama serve. Installation instructions are in docs/SETUP.md.',
        ),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> unload(String model) async {
    await json(
      '/api/generate',
      body: {'model': model, 'keep_alive': 0, 'stream': false},
    );
  }

  Stream<LlmEvent> respond(
    List<LlmMessage> messages,
    LlmSettings settings,
    CancellationToken token,
  ) async* {
    if (token.isCancelled) {
      yield const LlmFailed(
        LlmFailure(LlmErrorCode.cancelled, 'Reply stopped.'),
      );
      return;
    }
    if (_busy) {
      yield const LlmFailed(
        LlmFailure(
          LlmErrorCode.busy,
          'The previous local request is still stopping. Retry in a moment.',
        ),
      );
      return;
    }
    if (messages.isEmpty || messages.last.text.trim().isEmpty) {
      yield const LlmFailed(
        LlmFailure(LlmErrorCode.invalidRequest, 'Enter a message first.'),
      );
      return;
    }
    _busy = true;
    _finished = Completer<void>();
    final client = _client();
    _active = client;
    unawaited(token.whenCancelled.then((_) => client.close(force: true)));
    try {
      // Do not allow this app to load another model alongside one already resident.
      final resident = await json('/api/ps');
      for (final item in (resident['models'] as List? ?? [])) {
        final model = (item as Map)['name'] as String;
        if (model != settings.model) {
          yield LlmFailed(
            LlmFailure(
              LlmErrorCode.busy,
              'Another model is loaded ($model). Run: ollama stop $model, then retry. JARVIS will not load two models.',
            ),
          );
          return;
        }
      }
      if (token.isCancelled) {
        yield const LlmFailed(
          LlmFailure(LlmErrorCode.cancelled, 'Reply stopped.'),
        );
        return;
      }
      // A conservative UTF-8 byte allowance also bounds Gujarati, whose small-model
      // tokenization is much denser than English. Reserve system/output/framing.
      final system = settings.systemPromptFor(messages.last.text);
      final budget =
          settings.contextLength - utf8.encode(system).length - 256 - 128;
      int cost(LlmMessage m) => utf8.encode(m.text).length + 32;
      if (cost(messages.last) > budget) {
        yield const LlmFailed(
          LlmFailure(
            LlmErrorCode.contextLimit,
            'Message exceeds the local context allowance. Shorten it or increase context length in Settings.',
          ),
        );
        return;
      }
      final bounded = <LlmMessage>[];
      var count = 0;
      for (final m in messages.reversed) {
        if (count + cost(m) > budget) break;
        bounded.insert(0, m);
        count += cost(m);
      }
      // Keep conversational pairs and the latest user message, never an orphan assistant.
      while (bounded.isNotEmpty &&
          bounded.first.role == MessageRole.assistant) {
        bounded.removeAt(0);
      }
      final request = await client.postUrl(endpoint.resolve('/api/chat'));
      request.followRedirects = false;
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'model': settings.model,
          'messages': [
            {'role': 'system', 'content': system},
            ...bounded.map((m) => {'role': m.role.name, 'content': m.text}),
          ],
          'stream': true,
          'keep_alive': '${settings.keepAliveSeconds}s',
          'options': {
            'num_ctx': settings.contextLength,
            'num_predict': 256,
            'num_gpu': 0,
            'num_thread': 2,
            'temperature': 0,
            'seed': 42,
          },
        }),
      );
      final response = await request.close().timeout(responseTimeout);
      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          yield LlmFailed(
            LlmFailure(
              LlmErrorCode.modelMissing,
              'Model ${settings.model} is not pulled. Run: ollama pull ${settings.model}. Check its download size and obtain approval first; JARVIS never downloads models.',
            ),
          );
        } else {
          yield LlmFailed(
            LlmFailure(
              LlmErrorCode.requestFailed,
              'Ollama returned HTTP ${response.statusCode}. Run: ollama ps, then retry.',
            ),
          );
        }
        return;
      }
      var received = 0;
      await for (final line
          in _bounded(response)
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(responseTimeout)) {
        if (token.isCancelled) {
          yield const LlmFailed(
            LlmFailure(LlmErrorCode.cancelled, 'Reply stopped.'),
          );
          return;
        }
        if (line.trim().isEmpty) continue;
        received += line.length;
        if (line.length > 65536 || received > 1024 * 1024) {
          throw const FormatException('Oversized Ollama stream');
        }
        final decoded = jsonDecode(line);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException("Expected object");
        }
        final chunk = decoded;
        if (chunk['error'] != null) {
          yield const LlmFailed(
            LlmFailure(
              LlmErrorCode.requestFailed,
              'Ollama generation failed. Check ollama ps and retry; reduce context length if RAM is low.',
            ),
          );
          return;
        }
        final message = chunk['message'];
        if (message is! Map ||
            message['content'] is! String ||
            chunk['done'] is! bool) {
          throw const FormatException('Invalid chat chunk');
        }
        final text = message['content'] as String;
        if (text.isNotEmpty) yield TextDelta(text);
        if (chunk['done'] == true) {
          yield const LlmCompleted();
          return;
        }
      }
      yield const LlmFailed(
        LlmFailure(
          LlmErrorCode.malformedResponse,
          'Ollama stream ended without completion. Retry the reply.',
        ),
      );
    } on TimeoutException {
      yield LlmFailed(
        LlmFailure(
          token.isCancelled ? LlmErrorCode.cancelled : LlmErrorCode.timeout,
          token.isCancelled
              ? 'Reply stopped.'
              : 'Local reply timed out. Run: ollama ps; retry or choose fast mode.',
        ),
      );
    } on OllamaException catch (e) {
      yield LlmFailed(e.failure);
    } on FormatException {
      yield const LlmFailed(
        LlmFailure(
          LlmErrorCode.malformedResponse,
          'Ollama sent malformed chat data. Update/restart Ollama and retry.',
        ),
      );
    } on SocketException {
      yield LlmFailed(
        LlmFailure(
          token.isCancelled ? LlmErrorCode.cancelled : LlmErrorCode.unavailable,
          token.isCancelled
              ? 'Reply stopped.'
              : 'Ollama connection lost. Run: ollama serve, then retry.',
        ),
      );
    } catch (_) {
      yield LlmFailed(
        LlmFailure(
          token.isCancelled
              ? LlmErrorCode.cancelled
              : LlmErrorCode.requestFailed,
          token.isCancelled
              ? 'Reply stopped.'
              : 'Local request failed. Run: ollama ps, then retry.',
        ),
      );
    } finally {
      client.close(force: true);
      if (identical(_active, client)) _active = null;
      _busy = false;
      _finished?.complete();
      _finished = null;
    }
  }
}

class OllamaProvider implements LlmProvider {
  OllamaProvider(this.service, this.settings);
  final OllamaService service;
  final LlmSettings settings;
  @override
  String get label => settings.model;
  @override
  bool get isDemo => false;
  @override
  Stream<LlmEvent> respond(
    List<LlmMessage> messages, {
    required CancellationToken cancellation,
  }) => service.respond(messages, settings, cancellation);
}
