import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/developer/performance_settings.dart';
import '../../../core/design/motion_settings.dart';
import '../../orb/domain/orb_state.dart';
import '../../orb/presentation/core_orb.dart';
import '../domain/llm_provider.dart';
import 'chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  OrbState? _debugState;
  bool _failNext = false;
  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    if (_input.text.trim().isEmpty || ref.read(chatProvider).busy) return;
    final text = _input.text;
    _input.clear();
    ref.read(chatProvider.notifier).send(text, simulateFailure: _failNext);
    setState(() {
      _failNext = false;
      _debugState = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final provider = ref.watch(llmProvider);
    ref.listen(chatProvider, (previous, next) {
      final nearBottom =
          !_scroll.hasClients ||
          _scroll.position.maxScrollExtent - _scroll.offset < 100;
      if (nearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    });
    final autoState = switch (chat.phase) {
      ChatPhase.idle => OrbState.idle,
      ChatPhase.thinking => OrbState.thinking,
      ChatPhase.streaming => OrbState.speaking,
      ChatPhase.error => OrbState.error,
    };
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(AppTheme.spacing),
            children: [
              Text(
                provider.label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              const Text(
                'Development demo • scripted replies • no AI or network. '
                'Microphone off. Orb listening/speaking are visual previews; no audio.',
              ),
              CoreOrb(
                state: _debugState ?? autoState,
                reduceMotion: ref.watch(reduceMotionProvider),
                onFrame: ref.read(frameDiagnosticsProvider).record,
              ),
              ExpansionTile(
                title: const Text('Demo controls'),
                children: [
                  DropdownButtonFormField<OrbState?>(
                    initialValue: _debugState,
                    key: ValueKey(_debugState),
                    decoration: const InputDecoration(
                      labelText: 'Orb visual preview',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Follow chat'),
                      ),
                      ...OrbState.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      ),
                    ],
                    onChanged: (s) => setState(() => _debugState = s),
                  ),
                  SwitchListTile(
                    title: const Text('Simulate failure on next send'),
                    value: _failNext,
                    onChanged: chat.busy
                        ? null
                        : (v) => setState(() => _failNext = v),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing),
              if (chat.entries.isEmpty)
                const Text(
                  'Start a demo conversation in English or Gujarati. Nothing is saved.',
                ),
              for (var i = 0; i < chat.entries.length; i++)
                Card(
                  color: chat.entries[i].role == MessageRole.user
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainer,
                  margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.messagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.entries[i].role == MessageRole.user
                              ? 'You'
                              : 'Demo assistant',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppTheme.smallSpacing),
                        SelectableText(
                          chat.entries[i].text.isEmpty
                              ? (chat.entries[i].stopped
                                    ? 'No reply generated.'
                                    : chat.phase == ChatPhase.error
                                    ? 'No reply received.'
                                    : 'Waiting for demo reply…')
                              : chat.entries[i].text,
                          key: ValueKey('message-$i'),
                        ),
                        if (chat.entries[i].stopped)
                          const Text('Stopped • partial reply'),
                      ],
                    ),
                  ),
                ),
              if (chat.failure != null)
                Semantics(
                  liveRegion: true,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.messagePadding),
                      child: Column(
                        children: [
                          Text(chat.failure!.message),
                          TextButton(
                            onPressed: ref.read(chatProvider.notifier).retry,
                            child: const Text('Retry reply'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.messagePadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4000,
                    enabled: !chat.busy,
                    decoration: const InputDecoration(
                      labelText: 'Message the demo',
                      hintText: 'Hello / નમસ્તે',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: AppTheme.smallSpacing),
                if (chat.busy)
                  FilledButton.icon(
                    onPressed: ref.read(chatProvider.notifier).stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  )
                else
                  FilledButton(onPressed: _send, child: const Text('Send')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
