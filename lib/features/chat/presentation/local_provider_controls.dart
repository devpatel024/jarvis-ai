import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../data/ollama_provider.dart';
import '../domain/llm_settings.dart';
import '../domain/llm_provider.dart';
import 'chat_controller.dart';
import 'provider_settings.dart';

final localMemoryProvider = FutureProvider<int?>((ref) async {
  if (!Platform.isLinux) return null;
  try {
    for (final line in await File('/proc/meminfo').readAsLines()) {
      if (line.startsWith('MemAvailable:')) {
        return int.parse(line.split(RegExp(r'\s+'))[1]) * 1024;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
});
Future<void> chooseModel(
  BuildContext context,
  WidgetRef ref,
  String model,
) async {
  final previous = ref.read(providerSettingsProvider).model;
  if (model == previous) return;
  ref.read(chatProvider.notifier).stop();
  final service = ref.read(ollamaServiceProvider);
  try {
    await service.abortAndWait();
    if (previous != 'Mock demo') {
      final resident = await service.json('/api/ps');
      if ((resident['models'] as List? ?? []).any(
        (m) => m['name'] == previous,
      )) {
        await service.unload(previous);
      }
    }
  } on OllamaException catch (e) {
    // An unreachable server has no model that we can reach/load; demo still works.
    if (e.failure.code != LlmErrorCode.unavailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.failure.message)));
      }
      return;
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Model switch could not finish. Stop the current reply and retry.',
          ),
        ),
      );
    }
    return;
  }
  if (context.mounted) {
    ref.read(providerSettingsProvider.notifier).update(model: model);
  }
}

class ModelPicker extends ConsumerWidget {
  const ModelPicker({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(providerSettingsProvider).model;
    const choices = {
      'llama3.2:1b': 'llama3.2:1b · fast',
      'llama3.2:3b': 'llama3.2:3b · quality',
      'Mock demo': 'Mock demo · scripted',
    };
    if (compact) {
      return PopupMenuButton<String>(
        tooltip: 'Choose local model',
        initialValue: model,
        onSelected: (value) => chooseModel(context, ref, value),
        itemBuilder: (_) => choices.entries
            .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(model, style: Theme.of(context).textTheme.labelSmall),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey(model),
      initialValue: model,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Local provider / model'),
      items: choices.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (value) {
        if (value != null) chooseModel(context, ref, value);
      },
    );
  }
}

class LocalProviderSettings extends ConsumerStatefulWidget {
  const LocalProviderSettings({super.key});
  @override
  ConsumerState<LocalProviderSettings> createState() =>
      _LocalProviderSettingsState();
}

class _LocalProviderSettingsState extends ConsumerState<LocalProviderSettings> {
  String? _status;
  bool _checking = false;
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(providerSettingsProvider);
    final memory = ref.watch(localMemoryProvider).value;
    final storageIssue = ref.watch(storageIssueProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Local intelligence',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        const ModelPicker(),
        const SizedBox(height: 16),
        const Text(
          'Desktop endpoint: http://127.0.0.1:11434. CPU only. No cloud routing or automatic model downloads. On a phone this address is the phone itself; LAN-host support is not implemented in this step.',
        ),
        TextButton(
          onPressed: _checking
              ? null
              : () async {
                  setState(() {
                    _checking = true;
                    _status = null;
                  });
                  try {
                    final data = await ref
                        .read(ollamaServiceProvider)
                        .json('/api/tags');
                    final present = (data['models'] as List? ?? []).any(
                      (m) => m['name'] == config.model,
                    );
                    if (mounted) {
                      setState(
                        () => _status = config.demo
                            ? 'Demo selected. Ollama is reachable; no real request is needed.'
                            : present
                            ? 'Ollama is ready. ${config.model} is installed.'
                            : 'Model not pulled. Run: ollama pull ${config.model}. Check size and ask before a download over 1 GB. No model is downloaded by this button.',
                      );
                    }
                  } on OllamaException catch (e) {
                    if (mounted) setState(() => _status = e.failure.message);
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => _status =
                            'Ollama check failed. Run: ollama ps, then retry.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _checking = false);
                  }
                },
          child: Text(
            _checking ? 'Checking local Ollama…' : 'Check Ollama / model',
          ),
        ),
        if (_status != null) SelectableText(_status!),
        DropdownButtonFormField<int>(
          initialValue: config.contextLength,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Context tokens'),
          items: [
            for (final size in [1024, 2048, 4096])
              DropdownMenuItem(value: size, child: Text('$size tokens')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(chatProvider.notifier).stop();
              ref
                  .read(providerSettingsProvider.notifier)
                  .update(context: value);
            }
          },
        ),
        const Text(
          '2048 is the reference-laptop default. History is bounded conservatively; older turns may be omitted. Larger contexts use more RAM.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ReplyLanguage>(
          initialValue: config.language,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Reply language'),
          items: const [
            DropdownMenuItem(
              value: ReplyLanguage.matchInput,
              child: Text('Match English / Gujarati input'),
            ),
            DropdownMenuItem(
              value: ReplyLanguage.english,
              child: Text('English'),
            ),
            DropdownMenuItem(
              value: ReplyLanguage.gujarati,
              child: Text('Gujarati script'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(chatProvider.notifier).stop();
              ref
                  .read(providerSettingsProvider.notifier)
                  .update(language: value);
            }
          },
        ),
        const Text(
          'Language instructions cannot guarantee model quality. Gujarati text is supported; Gujarati voice remains unverified.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: config.keepAliveSeconds,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Unload model after idle',
          ),
          items: const [
            DropdownMenuItem(value: 0, child: Text('Immediately after reply')),
            DropdownMenuItem(value: 30, child: Text('30 seconds')),
            DropdownMenuItem(value: 60, child: Text('60 seconds')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(providerSettingsProvider.notifier)
                  .update(keepAlive: value);
            }
          },
        ),
        if (memory != null)
          Text(
            'Available host RAM: ${(memory / 1073741824).toStringAsFixed(2)} GiB${memory < 1073741824 ? '. Low memory: use fast mode or close other apps.' : ''}',
          ),
        TextButton(
          onPressed: () => ref.invalidate(localMemoryProvider),
          child: const Text('Refresh memory'),
        ),
        Text(
          'App RSS: ${(ProcessInfo.currentRss / 1048576).toStringAsFixed(1)} MiB. ${memory == null ? 'Host RAM metric unavailable on this platform.' : 'Host RAM is measured from Linux /proc/meminfo.'}',
        ),
        const SizedBox(height: 16),
        if (storageIssue != null) Text(storageIssue),
        Text(
          ref.watch(localStoreProvider) == null
              ? 'Capture/test session: history is not saved.'
              : 'Chats and settings are stored locally in an unencrypted SQLite database in the application-support directory. Delete a conversation after confirmation in History. The scratchpad remains temporary. No credentials or audio are stored.',
        ),
      ],
    );
  }
}
