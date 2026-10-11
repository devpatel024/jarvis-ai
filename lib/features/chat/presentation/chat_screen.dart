import '../../voice/presentation/voice_providers.dart';
import '../../voice/presentation/voice_controls.dart';
import '../../voice/domain/voice_contracts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/aurora_background.dart';
import '../../../core/design/motion_settings.dart';
import '../../../core/developer/performance_settings.dart';
import '../../orb/domain/orb_state.dart';
import '../../orb/presentation/core_orb.dart';
import '../domain/llm_provider.dart';
import 'chat_controller.dart';
import 'provider_settings.dart';
import 'local_provider_controls.dart';
import '../../../core/storage/local_store.dart';
import 'widgets/local_markdown.dart';

class DemoPreview extends Notifier<OrbState?> {
  @override
  OrbState? build() => null;
  void select(OrbState? value) => state = value;
}

final orbPreviewProvider = NotifierProvider<DemoPreview, OrbState?>(
  DemoPreview.new,
);

class DemoFailure extends Notifier<bool> {
  @override
  bool build() => false;
  void select(bool value) => state = value;
}

final demoFailureProvider = NotifierProvider<DemoFailure, bool>(
  DemoFailure.new,
);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.tier = OrbTier.balanced,
    this.reduced = false,
  });
  final OrbTier tier;
  final bool reduced;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  bool _editing = false, _atBottom = true, _focused = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackScroll);
    _focus.addListener(_trackFocus);
  }

  void _trackFocus() {
    if (mounted) setState(() => _focused = _focus.hasFocus);
  }

  void _trackScroll() {
    final bottom =
        !_scroll.hasClients ||
        _scroll.position.maxScrollExtent - _scroll.offset < 100;
    if (bottom != _atBottom && mounted) setState(() => _atBottom = bottom);
  }

  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send([String? suggestion]) {
    final prompt = (suggestion ?? _input.text).trim();
    if (prompt.isEmpty || ref.read(chatProvider).busy) return;
    final controller = ref.read(chatProvider.notifier);
    if (_editing) {
      controller.editLast(prompt);
    } else {
      controller.send(prompt, simulateFailure: ref.read(demoFailureProvider));
    }
    ref.read(demoFailureProvider.notifier).select(false);
    ref.read(orbPreviewProvider.notifier).select(null);
    _input.clear();
    setState(() => _editing = false);
    _bottom();
  }

  void _edit(String text) {
    _input.text = text;
    setState(() => _editing = true);
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final voice = ref.watch(voiceSessionProvider);
    final actualTier = voice.phase == VoicePhase.transcribing
        ? OrbTier.lite
        : widget.tier;
    final reduced =
        widget.reduced ||
        ref.watch(reduceMotionProvider) ||
        MediaQuery.disableAnimationsOf(context);
    final state =
        (voice.active || voice.phase == VoicePhase.error
            ? switch (voice.phase) {
                VoicePhase.listening => OrbState.listening,
                VoicePhase.transcribing ||
                VoicePhase.thinking => OrbState.thinking,
                VoicePhase.speaking => OrbState.speaking,
                VoicePhase.error => OrbState.error,
                VoicePhase.idle => OrbState.idle,
              }
            : null) ??
        ref.watch(orbPreviewProvider) ??
        switch (chat.phase) {
          ChatPhase.idle => OrbState.idle,
          ChatPhase.thinking => OrbState.thinking,
          ChatPhase.streaming => OrbState.speaking,
          ChatPhase.error => OrbState.error,
        };
    ref.listen(chatProvider, (previous, next) {
      if (previous?.busy != next.busy) ref.invalidate(localMemoryProvider);
      if (previous?.activeId != next.activeId) {
        _input.clear();
        _editing = false;
        _bottom();
      } else if (_atBottom) {
        _bottom();
      }
    });
    final c = JarvisColors.of(context);
    final memory = ref.watch(localMemoryProvider).value;
    final storageIssue = ref.watch(storageIssueProvider).value;
    return VoiceKeyboard(
      isEditing: () => _focus.hasFocus,
      child: Column(
        children: [
          if (storageIssue != null)
            Padding(
              padding: const EdgeInsets.all(AppTheme.smallSpacing),
              child: Text(
                storageIssue,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (memory != null && memory < 1073741824)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Low available RAM. Use fast mode or close other apps before generating.',
              ),
            ),
          if (chat.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing),
              child: Row(
                children: [
                  CoreOrb(
                    state: state,
                    reduceMotion: reduced,
                    tier: actualTier,
                    microphoneLevel: voice.level,
                    size: AppTheme.compactOrbSize,
                  ),
                  const SizedBox(width: AppTheme.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.sessions
                              .firstWhere((s) => s.id == chat.activeId)
                              .title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          chat.busy
                              ? '${ref.watch(llmProvider).isDemo ? 'Scripted' : 'Local'} reply ${chat.phase == ChatPhase.thinking ? 'on its way' : 'streaming'}'
                              : '${ref.watch(llmProvider).label} · ${voice.phase == VoicePhase.listening ? 'microphone active' : 'microphone off'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Scrollbar(
                  controller: _scroll,
                  thumbVisibility: chat.entries.isEmpty,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppTheme.spacing),
                    itemCount: chat.entries.isEmpty
                        ? 1
                        : chat.entries.length + (chat.failure != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (chat.entries.isEmpty) {
                        return _empty(context, state, reduced);
                      }
                      if (index == chat.entries.length) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppTheme.readingWidth,
                            ),
                            child: GlassPanel(
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppTheme.messagePadding,
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.error_outline),
                                    Text(chat.failure!.message),
                                    TextButton(
                                      onPressed: ref
                                          .read(chatProvider.notifier)
                                          .retry,
                                      child: const Text('Retry reply'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      final entry = chat.entries[index];
                      final lastUser =
                          index ==
                          chat.entries.lastIndexWhere(
                            (e) => e.role == MessageRole.user,
                          );
                      final lastAssistant =
                          index == chat.entries.length - 1 &&
                          entry.role == MessageRole.assistant;
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppTheme.readingWidth,
                          ),
                          child: MessageBubble(
                            key: ValueKey('${chat.activeId}-$index'),
                            entry: entry,
                            index: index,
                            streaming:
                                lastAssistant &&
                                chat.phase == ChatPhase.streaming,
                            thinking:
                                lastAssistant &&
                                chat.phase == ChatPhase.thinking,
                            reduced: reduced || widget.tier == OrbTier.lite,
                            tier: widget.tier,
                            onEdit: lastUser && !chat.busy
                                ? () => _edit(entry.text)
                                : null,
                            onRegenerate: lastAssistant && !chat.busy
                                ? ref.read(chatProvider.notifier).regenerate
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!_atBottom && chat.entries.isNotEmpty)
                  Positioned(
                    right: AppTheme.messagePadding,
                    bottom: AppTheme.messagePadding,
                    child: FloatingActionButton.small(
                      tooltip: 'Scroll to bottom',
                      onPressed: _bottom,
                      child: const Icon(Icons.arrow_downward),
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.readingWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.messagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_editing)
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Editing your last message'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _editing = false);
                              _input.clear();
                            },
                            child: const Text('Cancel edit'),
                          ),
                        ],
                      ),
                    _ComposerRing(
                      focused: _focused,
                      reduced: reduced || widget.tier == OrbTier.lite,
                      tier: widget.tier,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.smallSpacing),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.enter &&
                                      !HardwareKeyboard
                                          .instance
                                          .isShiftPressed) {
                                    if (_input.value.composing.isValid &&
                                        !_input.value.composing.isCollapsed) {
                                      return KeyEventResult.ignored;
                                    }
                                    _send();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: TextField(
                                  key: const ValueKey('composer'),
                                  controller: _input,
                                  focusNode: _focus,
                                  minLines: 1,
                                  maxLines: 5,
                                  maxLength: 4000,
                                  enabled: !chat.busy && !voice.active,
                                  keyboardType: TextInputType.multiline,
                                  decoration: const InputDecoration(
                                    labelText: 'Message Jarvis',
                                    hintText: 'Ask something / કંઈક પૂછો',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    counterText: '',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.smallSpacing),
                            IconButton.filled(
                              tooltip: chat.busy ? 'Stop' : 'Send',
                              onPressed: chat.busy
                                  ? ref.read(chatProvider.notifier).stop
                                  : _send,
                              icon: Icon(
                                chat.busy
                                    ? Icons.stop_rounded
                                    : Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VoiceControls(),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppTheme.messagePadding,
                      children: [
                        Tooltip(
                          message:
                              'Attachments are not available in this slice. Paste text into the composer.',
                          child: Text(
                            'Attachments · coming soon',
                            style: TextStyle(
                              color: c.muted,
                              fontSize: AppTheme.helperSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, OrbState state, bool reduced) => Padding(
    padding: EdgeInsets.only(
      top: MediaQuery.sizeOf(context).width >= AppTheme.desktopBreakpoint
          ? AppTheme.heroTopSpacing
          : 0,
      bottom: AppTheme.spacing,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.readingWidth),
        child: Column(
          children: [
            CoreOrb(
              state: state,
              reduceMotion: reduced,
              tier:
                  ref.watch(voiceSessionProvider).phase ==
                      VoicePhase.transcribing
                  ? OrbTier.lite
                  : widget.tier,
              microphoneLevel: ref.watch(voiceSessionProvider).level,
              size: MediaQuery.sizeOf(context).width < AppTheme.railBreakpoint
                  ? AppTheme.phoneOrbSize
                  : AppTheme.heroOrbSize,
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: reduced || widget.tier == OrbTier.lite ? 1 : 0,
                end: 1,
              ),
              duration: reduced ? Duration.zero : AppTheme.transition,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, (1 - value) * AppTheme.messagePadding),
                child: child,
              ),
              child: Text(
                'A little spark.\nA world of possibilities.',
                textAlign: TextAlign.center,
                style:
                    MediaQuery.sizeOf(context).width < AppTheme.railBreakpoint
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: AppTheme.messagePadding),
            Text(
              'Hello / નમસ્તે',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.smallSpacing),
            Text(
              ref.watch(providerSettingsProvider).demo
                  ? (ref.watch(localStoreProvider) == null
                        ? 'A local, scripted demo. No AI provider connected.\nNothing is saved. No requests leave your device.'
                        : 'Scripted demo mode. Chats are saved locally.\nNo AI request leaves your device.')
                  : 'Local Ollama · ${ref.watch(providerSettingsProvider).model}.\nReplies run on this computer. Chats are saved locally.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacing),
            Wrap(
              spacing: AppTheme.smallSpacing,
              runSpacing: AppTheme.smallSpacing,
              alignment: WrapAlignment.center,
              children: [
                for (final (i, prompt) in [
                  'Plan my day',
                  'Show a code example',
                  'નમસ્તે',
                  'મારા દિવસનું આયોજન કરો',
                ].indexed)
                  OutlinedButton.icon(
                    icon: Icon(
                      [
                        Icons.wb_sunny_outlined,
                        Icons.code,
                        Icons.auto_awesome_outlined,
                        Icons.explore_outlined,
                      ][i],
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: JarvisColors.of(context).ink,
                      backgroundColor: JarvisColors.of(
                        context,
                      ).accents[i % 3].withValues(alpha: AppTheme.chipTint),
                      padding: const EdgeInsets.all(AppTheme.smallSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.controlRadius,
                        ),
                      ),
                    ),
                    label: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.sizeOf(context).width <
                                AppTheme.railBreakpoint
                            ? MediaQuery.sizeOf(context).width -
                                  AppTheme.spacing * 2 -
                                  AppTheme.compactOrbSize
                            : AppTheme.readingWidth / 2,
                      ),
                      child: Text(
                        prompt,
                        softWrap: true,
                        maxLines: 4,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    onPressed: () => _send(prompt),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ComposerRing extends StatefulWidget {
  const _ComposerRing({
    required this.focused,
    required this.reduced,
    required this.tier,
    required this.child,
  });
  final bool focused, reduced;
  final OrbTier tier;
  final Widget child;
  @override
  State<_ComposerRing> createState() => _ComposerRingState();
}

class _ComposerRingState extends State<_ComposerRing> {
  final _clock = MotionClock();
  void _sync() => _clock.start(
    AppTheme.orbCycle,
    widget.tier,
    !widget.focused || widget.reduced,
  );
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_ComposerRing old) {
    super.didUpdateWidget(old);
    if (old.focused != widget.focused ||
        old.reduced != widget.reduced ||
        old.tier != widget.tier) {
      _sync();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _clock,
      child: widget.child,
      builder: (context, child) {
        final c = JarvisColors.of(context);
        return Container(
          padding: EdgeInsets.all(
            widget.focused ? AppTheme.hairline * 2 : AppTheme.hairline,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            gradient: LinearGradient(
              colors: c.accents,
              transform: GradientRotation(_clock.value * 6.283),
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(
                AppTheme.radius - AppTheme.hairline,
              ),
            ),
            child: child,
          ),
        );
      },
    ),
  );
}

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.entry,
    required this.index,
    required this.streaming,
    required this.thinking,
    required this.reduced,
    required this.tier,
    this.onEdit,
    this.onRegenerate,
  });
  final ChatEntry entry;
  final int index;
  final bool streaming, thinking, reduced;
  final OrbTier tier;
  final VoidCallback? onEdit, onRegenerate;
  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _hover = false;
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.entry.text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message copied')));
    }
  }

  void _actions() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Copy message'),
            onTap: () {
              Navigator.pop(context);
              _copy();
            },
          ),
          if (widget.onEdit != null)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit last message'),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit!();
              },
            ),
          if (widget.onRegenerate != null)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Regenerate reply'),
              onTap: () {
                Navigator.pop(context);
                widget.onRegenerate!();
              },
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final user = widget.entry.role == MessageRole.user,
        c = JarvisColors.of(context);
    final time = widget.entry.timestamp;
    final body = RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onLongPress: _actions,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.messagePadding),
            child: Align(
              alignment: user ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: AppTheme.bubbleWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!user)
                      CoreOrb(
                        state: widget.streaming
                            ? OrbState.speaking
                            : OrbState.idle,
                        reduceMotion: true,
                        tier: OrbTier.lite,
                        size: AppTheme.avatarSize,
                      ),
                    if (!user) const SizedBox(width: AppTheme.smallSpacing),
                    Expanded(
                      child: GlassPanel(
                        user: user,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppTheme.messagePadding,
                          ),
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: user ? c.userInk : c.ink),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user
                                            ? 'You'
                                            : widget.entry.provider ==
                                                  'Mock demo'
                                            ? 'Jarvis · scripted demo'
                                            : 'Jarvis · ${widget.entry.provider}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge!
                                            .copyWith(
                                              color: user ? c.userInk : c.ink,
                                            ),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Message time',
                                      child: Text(
                                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: AppTheme.captionSize,
                                          color: user ? c.userInk : c.muted,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Message actions',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: _actions,
                                      icon: Icon(
                                        Icons.more_horiz,
                                        color: user ? c.userInk : c.muted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.thinking)
                                  Semantics(
                                    liveRegion: true,
                                    label: widget.entry.provider == 'Mock demo'
                                        ? 'Thinking: preparing a scripted reply'
                                        : 'Thinking: waiting for local Ollama',
                                    child: Text(
                                      widget.entry.provider == 'Mock demo'
                                          ? 'Preparing a demo reply…'
                                          : 'Waiting for local Ollama…',
                                    ),
                                  )
                                else
                                  LocalMarkdown(
                                    key: ValueKey('message-${widget.index}'),
                                    text: widget.entry.text.isEmpty
                                        ? (widget.entry.stopped
                                              ? 'No reply generated.'
                                              : 'No reply received.')
                                        : widget.entry.text,
                                    color: user ? c.userInk : c.ink,
                                  ),
                                if (widget.streaming)
                                  Semantics(
                                    liveRegion: true,
                                    label: 'Reply streaming',
                                    child: Text('▌'),
                                  ),
                                if (widget.entry.stopped)
                                  const Text('Stopped · partial reply'),
                                if (_hover)
                                  Wrap(
                                    children: [
                                      TextButton(
                                        onPressed: _copy,
                                        child: Text(
                                          'Copy',
                                          style: TextStyle(
                                            color: user ? c.userInk : c.ink,
                                          ),
                                        ),
                                      ),
                                      if (widget.onEdit != null)
                                        TextButton(
                                          onPressed: widget.onEdit,
                                          child: Text(
                                            'Edit last message',
                                            style: TextStyle(
                                              color: user ? c.userInk : c.ink,
                                            ),
                                          ),
                                        ),
                                      if (widget.onRegenerate != null)
                                        TextButton(
                                          onPressed: widget.onRegenerate,
                                          child: Text(
                                            'Regenerate',
                                            style: TextStyle(
                                              color: user ? c.userInk : c.ink,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: widget.reduced ? 1 : 0, end: 1),
      duration: widget.reduced ? Duration.zero : AppTheme.messageEntry,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(
          0,
          (1 - (value * 1.3 - (widget.index % 3) * .15).clamp(0, 1)) *
              AppTheme.messagePadding,
        ),
        child: child,
      ),
      child: body,
    );
  }
}
