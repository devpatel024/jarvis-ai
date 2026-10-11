import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/features/chat/data/ollama_provider.dart';
import 'package:jarvis/features/chat/domain/llm_provider.dart';
import 'package:jarvis/features/chat/domain/llm_settings.dart';

void main() {
  late HttpServer server;
  late OllamaService service;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    service = OllamaService(
      endpoint: Uri.parse('http://127.0.0.1:${server.port}'),
      responseTimeout: const Duration(milliseconds: 500),
    );
  });
  tearDown(() async {
    service.close();
    await server.close(force: true);
  });
  void serve(
    Future<void> Function(HttpRequest) handle, {
    List<String> loaded = const [],
  }) {
    server.listen((r) async {
      if (r.uri.path == '/api/ps') {
        r.response.write(
          jsonEncode({
            'models': loaded.map((n) => {'name': n}).toList(),
          }),
        );
        await r.response.close();
      } else {
        await handle(r);
      }
    });
  }

  Stream<LlmEvent> reply(
    CancellationToken token, {
    LlmSettings settings = const LlmSettings(),
  }) => service.respond(
    [const LlmMessage(MessageRole.user, 'નમસ્તે')],
    settings,
    token,
  );
  test(
    'NDJSON UTF8 streaming, CPU options and Gujarati language instructions',
    () async {
      serve((r) async {
        final body = jsonDecode(await utf8.decoder.bind(r).join());
        expect(body['options']['num_ctx'], 2048);
        expect(body['options']['num_gpu'], 0);
        expect(body['keep_alive'], '30s');
        expect(body['messages'][0]['content'], contains('never Hindi'));
        r.response.headers.contentType = ContentType('application', 'x-ndjson');
        final bytes = utf8.encode(
          '${jsonEncode({
            'message': {'content': 'નમસ્તે '},
            'done': false,
          })}\n${jsonEncode({
            'message': {'content': 'Hello'},
            'done': true,
          })}\n',
        );
        r.response.add(bytes.sublist(0, 36));
        await r.response.flush();
        r.response.add(bytes.sublist(36));
        await r.response.close();
      });
      final events = await reply(CancellationToken()).toList();
      expect(
        events.whereType<TextDelta>().map((e) => e.text).join(),
        'નમસ્તે Hello',
      );
      expect(events.last, isA<LlmCompleted>());
    },
  );
  test(
    'Stop closes the live connection and releases the serialization guard',
    () async {
      final disconnected = Completer<void>();
      serve((r) async {
        await r.drain<void>();
        r.response.headers.contentType = ContentType('application', 'x-ndjson');
        r.response.contentLength = 1000000;
        final socket = await r.response.detachSocket();
        socket.listen(
          (_) {},
          onDone: () {
            if (!disconnected.isCompleted) disconnected.complete();
          },
          onError: (Object e) {
            if (!disconnected.isCompleted) disconnected.complete();
          },
        );
        socket.write(
          '${jsonEncode({
            'message': {'content': 'partial'},
            'done': false,
          })}\n',
        );
        await socket.flush();
        // Keep response open. Client cancellation must abort it.
      });
      final token = CancellationToken();
      final events = <LlmEvent>[];
      await for (final e in reply(token)) {
        events.add(e);
        if (e is TextDelta) token.cancel();
      }
      await disconnected.future.timeout(const Duration(seconds: 2));
      expect(events.whereType<TextDelta>().single.text, 'partial');
      expect(events.whereType<LlmCompleted>(), isEmpty);
      expect(
        events.whereType<LlmFailed>().single.failure.code,
        LlmErrorCode.cancelled,
      );
    },
  );
  for (final (status, code) in [
    (404, LlmErrorCode.modelMissing),
    (500, LlmErrorCode.requestFailed),
    (302, LlmErrorCode.requestFailed),
  ]) {
    test('HTTP $status has typed error and no redirect', () async {
      serve((r) async {
        r.response.statusCode = status;
        r.response.headers.set('Location', 'https://example.com');
        await r.response.close();
      });
      final events = await reply(CancellationToken()).toList();
      expect(events.single, isA<LlmFailed>());
      expect((events.single as LlmFailed).failure.code, code);
    });
  }
  for (final malformed in [
    'not json',
    '[]',
    '{"message":{},"done":false}',
    '{"error":"failure"}',
  ]) {
    test('Malformed or failed chunk: $malformed', () async {
      serve((r) async {
        r.response.write('$malformed\n');
        await r.response.close();
      });
      final events = await reply(CancellationToken()).toList();
      expect(events.last, isA<LlmFailed>());
      expect(
        (events.last as LlmFailed).failure.code,
        malformed.contains('error')
            ? LlmErrorCode.requestFailed
            : LlmErrorCode.malformedResponse,
      );
    });
  }
  test('Incomplete stream is a typed failure', () async {
    serve((r) async {
      await r.drain<void>();
      r.response.write(
        '${jsonEncode({
          'message': {'content': 'partial'},
          'done': false,
        })}\n',
      );
      await r.response.close();
    });
    final events = await reply(CancellationToken()).toList();
    expect(
      (events.last as LlmFailed).failure.code,
      LlmErrorCode.malformedResponse,
    );
  });
  test('Pre-cancelled request never contacts server', () async {
    final token = CancellationToken()..cancel();
    expect((await reply(token).toList()).single, isA<LlmFailed>());
  });
  test('Refuses a second resident model', () async {
    serve((r) async {
      fail('Must not start another generation');
    }, loaded: ['llama3.2:3b']);
    expect(
      ((await reply(CancellationToken()).toList()).single as LlmFailed)
          .failure
          .code,
      LlmErrorCode.busy,
    );
  });
  test('Stalled response times out and releases connection', () async {
    serve((r) async {
      await r.drain<void>();
    });
    final events = await reply(CancellationToken()).toList();
    expect((events.last as LlmFailed).failure.code, LlmErrorCode.timeout);
  });
  test('Oversized input is rejected before sending generation', () async {
    serve((r) async {
      fail('Must not generate oversized input');
    });
    final events = await service
        .respond(
          [LlmMessage(MessageRole.user, 'x' * 4097)],
          const LlmSettings(),
          CancellationToken(),
        )
        .toList();
    expect(
      (events.single as LlmFailed).failure.code,
      LlmErrorCode.contextLimit,
    );
  });
  test('Overlong stream without newline is bounded before parsing', () async {
    serve((r) async {
      r.response.write('x' * (1024 * 1024 + 1));
      await r.response.close();
    });
    final events = await reply(CancellationToken()).toList();
    expect(
      (events.last as LlmFailed).failure.code,
      LlmErrorCode.malformedResponse,
    );
  });
  test(
    'Gujarati UTF8 input cannot bypass the bounded context allowance',
    () async {
      serve((r) async {
        fail('Must reject before generation');
      });
      final events = await service
          .respond(
            [LlmMessage(MessageRole.user, 'ન' * 600)],
            const LlmSettings(),
            CancellationToken(),
          )
          .toList();
      expect(
        (events.single as LlmFailed).failure.code,
        LlmErrorCode.contextLimit,
      );
    },
  );
  test('Language matching gives English one explicit instruction', () {
    const settings = LlmSettings();
    expect(settings.systemPromptFor('Hello'), contains('Reply in English'));
    expect(settings.systemPromptFor('Hello'), isNot(contains('Gujarati')));
    expect(settings.systemPromptFor('નમસ્તે'), contains('Reply in Gujarati'));
    expect(
      const LlmSettings(
        language: ReplyLanguage.english,
      ).systemPromptFor('નમસ્તે'),
      contains('Reply in English'),
    );
  });
  test('External and credential-bearing endpoint rejected', () {
    expect(
      () => OllamaService(endpoint: Uri.parse('https://example.com')),
      throwsArgumentError,
    );
    expect(
      () => OllamaService(endpoint: Uri.parse('http://key@127.0.0.1:11434')),
      throwsArgumentError,
    );
  });
}
