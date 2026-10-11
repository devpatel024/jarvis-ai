import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/jarvis_app.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/aurora_background.dart';
import '../../../core/design/motion_settings.dart';
import '../../../core/developer/performance_settings.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../chat/presentation/chat_controller.dart';
import '../../orb/domain/orb_state.dart';

class ShellPage extends Notifier<int> {
  @override
  int build() => 0;
  void select(int page) => state = page;
}

final shellPageProvider = NotifierProvider<ShellPage, int>(ShellPage.new);

class AssistantShell extends ConsumerStatefulWidget {
  const AssistantShell({super.key});
  @override
  ConsumerState<AssistantShell> createState() => _AssistantShellState();
}

class _AssistantShellState extends ConsumerState<AssistantShell> {
  final _scratch = TextEditingController();
  bool _sidebar = true, _reduced = false;
  OrbTier _tier = OrbTier.balanced;
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings);
  }

  void _timings(List<FrameTiming> frames) {
    if (!mounted) return;
    for (final frame in frames) {
      ref
          .read(qualityProvider.notifier)
          .record(
            _tier,
            frame.buildDuration.inMicroseconds,
            frame.rasterDuration.inMicroseconds,
            reduced: _reduced,
          );
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    _scratch.dispose();
    super.dispose();
  }

  void _page(int value) => ref.read(shellPageProvider.notifier).select(value);
  void _new() {
    ref.read(chatProvider.notifier).newChat();
    _page(0);
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _rename(ChatSummary chat) async {
    final controller = TextEditingController(text: chat.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Conversation name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    // Dialog route may still use its controller during the closing animation.
    await Future<void>.delayed(AppTheme.transition);
    controller.dispose();
    if (result != null && mounted) {
      ref.read(chatProvider.notifier).renameChat(chat.id, result);
    }
  }

  Future<void> _delete(ChatSummary chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          'Delete “${chat.title}” from this session? This cannot be undone. Any active reply in this conversation will stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(chatProvider.notifier).deleteChat(chat.id);
      _toast('Conversation deleted');
    }
  }

  void _commandPalette() => showDialog<void>(
    context: context,
    builder: (context) => _CommandPalette(onNew: _new, onPage: _page),
  );
  @override
  Widget build(BuildContext context) {
    final page = ref.watch(shellPageProvider);
    final sessions = ref.watch(chatProvider.select((s) => s.sessions));
    final active = ref.watch(chatProvider.select((s) => s.activeId));
    _reduced =
        ref.watch(reduceMotionProvider) ||
        MediaQuery.disableAnimationsOf(context);
    _tier = _reduced ? OrbTier.lite : ref.watch(qualityProvider).tier;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _commandPalette,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _new,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            ref.read(chatProvider.notifier).stop(),
      },
      child: Focus(
        autofocus: true,
        child: AuroraBackground(
          tier: _tier,
          reduced: _reduced,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rail = constraints.maxWidth >= AppTheme.railBreakpoint;
              final desktop =
                  constraints.maxWidth >= AppTheme.desktopBreakpoint;
              final c = JarvisColors.of(context);
              return Scaffold(
                appBar: AppBar(
                  title: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.smallSpacing),
                      Expanded(
                        child: Text(
                          'JARVIS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: AppTheme.brandTracking,
                              ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    if (rail)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.smallSpacing,
                          vertical: AppTheme.smallSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: c.accents.first.withValues(
                            alpha: AppTheme.statusTint,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        child: Text(
                          'Offline demo',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    if (rail) const SizedBox(width: AppTheme.smallSpacing),
                    if (rail)
                      Tooltip(
                        message:
                            'Visual quality${_reduced ? ': reduced motion' : ''}',
                        child: Text(
                          _tier.label,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Commands (Ctrl+K)',
                      onPressed: _commandPalette,
                      icon: const Icon(Icons.search),
                    ),
                  ],
                  bottom: rail
                      ? null
                      : PreferredSize(
                          preferredSize: Size.fromHeight(
                            MediaQuery.textScalerOf(
                              context,
                            ).scale(AppTheme.mobileStatusHeight),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.messagePadding,
                              vertical: AppTheme.smallSpacing,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.smallSpacing,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.accents.first.withValues(
                                          alpha: AppTheme.statusTint,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.pillRadius,
                                        ),
                                      ),
                                      child: Text(
                                        'Offline demo',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.smallSpacing),
                                Tooltip(
                                  message:
                                      'Visual quality${_reduced ? ': reduced motion' : ''}',
                                  child: Text(
                                    _tier.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                body: SafeArea(
                  child: Row(
                    children: [
                      if (rail)
                        SizedBox(
                          width: AppTheme.railWidth,
                          child: NavigationRail(
                            selectedIndex: page,
                            onDestinationSelected: _page,
                            labelType: NavigationRailLabelType.all,
                            leading: IconButton.filled(
                              tooltip: 'New chat (Ctrl+N)',
                              onPressed: _new,
                              icon: const Icon(Icons.add),
                            ),
                            trailing: desktop
                                ? IconButton(
                                    tooltip: _sidebar
                                        ? 'Collapse chat list'
                                        : 'Expand chat list',
                                    onPressed: () =>
                                        setState(() => _sidebar = !_sidebar),
                                    icon: Icon(
                                      _sidebar
                                          ? Icons.chevron_left
                                          : Icons.chevron_right,
                                    ),
                                  )
                                : null,
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.chat_bubble_outline),
                                label: Text('Chat'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.history),
                                label: Text('History'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                label: Text('Settings'),
                              ),
                            ],
                          ),
                        ),
                      if (desktop && _sidebar)
                        Container(
                          width: AppTheme.sidebarWidth,
                          padding: const EdgeInsets.all(AppTheme.smallSpacing),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: c.accents[1].withValues(
                                  alpha: AppTheme.chipTint,
                                ),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(AppTheme.smallSpacing),
                                child: Text('YOUR CONVERSATIONS'),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(AppTheme.smallSpacing),
                                child: Text('Session only · not saved'),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: sessions.length,
                                  itemBuilder: (context, index) => _session(
                                    sessions[index],
                                    active,
                                    compact: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: _reduced || _tier == OrbTier.lite
                              ? Duration.zero
                              : AppTheme.transition,
                          transitionBuilder: (child, animation) =>
                              SlideTransition(
                                position: Tween(
                                  begin: const Offset(AppTheme.pageDrift, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                          child: KeyedSubtree(
                            key: ValueKey(page),
                            child: page == 0
                                ? ChatScreen(tier: _tier, reduced: _reduced)
                                : Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: AppTheme.readingWidth,
                                      ),
                                      child: ListView(
                                        padding: const EdgeInsets.all(
                                          AppTheme.spacing,
                                        ),
                                        children: page == 1
                                            ? _history(sessions, active)
                                            : _settings(context),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: rail
                    ? null
                    : NavigationBar(
                        selectedIndex: page,
                        onDestinationSelected: _page,
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.chat_bubble_outline),
                            label: 'Chat',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.history),
                            label: 'History',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.settings_outlined),
                            label: 'Settings',
                          ),
                        ],
                      ),
                floatingActionButton: !rail && page == 1
                    ? FloatingActionButton(
                        tooltip: 'New chat',
                        onPressed: _new,
                        child: const Icon(Icons.add),
                      )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _session(ChatSummary chat, String active, {bool compact = false}) =>
      ListTile(
        selected: chat.id == active,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        ),
        title: Text(
          chat.title,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          ref.read(chatProvider.notifier).selectChat(chat.id);
          _page(0);
        },
        trailing: PopupMenuButton<String>(
          tooltip: 'Conversation actions',
          onSelected: (value) =>
              value == 'rename' ? _rename(chat) : _delete(chat),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      );
  List<Widget> _history(List<ChatSummary> sessions, String active) => [
    Text(
      'Your conversations',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    const SizedBox(height: AppTheme.smallSpacing),
    const Text(
      'Only in this session. Closing Jarvis clears every conversation.',
    ),
    const SizedBox(height: AppTheme.messagePadding),
    for (final chat in sessions) _session(chat, active),
    const SizedBox(height: AppTheme.spacing),
    ExpansionTile(
      title: const Text('Unicode scratchpad'),
      children: [
        const Text(
          'A temporary space for English and Gujarati. Nothing is saved.',
        ),
        TextField(
          controller: _scratch,
          minLines: 3,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Scratchpad',
            hintText: 'Hello / નમસ્તે',
          ),
        ),
        TextButton(
          onPressed: _scratch.clear,
          child: const Text('Clear scratchpad'),
        ),
      ],
    ),
  ];
  List<Widget> _settings(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final quality = ref.watch(qualityProvider);
    return [
      Text('Make it yours.', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: AppTheme.smallSpacing),
      const Text(
        'Appearance changes instantly. Settings stay in this session.',
      ),
      const SizedBox(height: AppTheme.spacing),
      Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.messagePadding),
      DropdownButtonFormField<ThemeMode>(
        initialValue: ref.watch(themeProvider),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Theme'),
        items: const [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text('Follow system', overflow: TextOverflow.ellipsis),
          ),
          DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
        ],
        onChanged: (value) {
          if (value != null) ref.read(themeProvider.notifier).select(value);
        },
      ),
      const SizedBox(height: AppTheme.messagePadding),
      DropdownButtonFormField<AppPalette>(
        key: ValueKey(palette),
        initialValue: palette,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Color palette'),
        items: AppPalette.values
            .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
            .toList(),
        onChanged: (p) {
          if (p != null) ref.read(paletteProvider.notifier).select(p);
        },
      ),
      const SizedBox(height: AppTheme.messagePadding),
      Wrap(
        spacing: AppTheme.smallSpacing,
        runSpacing: AppTheme.smallSpacing,
        children: [
          for (final p in AppPalette.values)
            Semantics(
              selected: palette == p,
              button: true,
              label: 'Preview ${p.label}',
              child: Tooltip(
                message: p.label,
                child: InkWell(
                  onTap: () => ref.read(paletteProvider.notifier).select(p),
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  child: Container(
                    width: AppTheme.swatchWidth,
                    padding: const EdgeInsets.all(AppTheme.smallSpacing),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppTheme.controlRadius,
                      ),
                      border: Border.all(
                        color: palette == p
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: palette == p ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: AppTheme.swatchHeight,
                          decoration: BoxDecoration(
                            gradient: AppTheme.colors(
                              p,
                              Theme.of(context).brightness,
                            ).accentGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.smallSpacing,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.smallSpacing),
                        Text(
                          p.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppTheme.spacing),
      SwitchListTile(
        title: const Text('Reduce motion'),
        subtitle: const Text(
          'Also respects the OS animation accessibility setting.',
        ),
        value: ref.watch(reduceMotionProvider),
        onChanged: ref.read(reduceMotionProvider.notifier).setReduced,
      ),
      DropdownButtonFormField<OrbTier?>(
        key: ValueKey(quality.manual),
        initialValue: quality.manual,
        hint: const Text('Automatic'),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Visual quality'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Automatic')),
          ...OrbTier.values.map(
            (t) => DropdownMenuItem(value: t, child: Text(t.label)),
          ),
        ],
        onChanged: ref.read(qualityProvider.notifier).select,
      ),
      const SizedBox(height: AppTheme.smallSpacing),
      const Text(
        'Ultra: slow aurora and particles. Balanced: static backdrop with an animated orb. Lite: static backdrop and gentle pulse. Reduced motion pauses all animation, including manual quality choices.',
      ),
      const SizedBox(height: AppTheme.spacing),
      Text('Private by design', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.smallSpacing),
      const Text(
        'MockProvider uses scripted replies. No real AI provider is connected. No network, microphone capture, audio, telemetry or saved history. English and Gujarati text are supported; Gujarati voice is unverified. Interface language is English.',
      ),
      const SizedBox(height: AppTheme.spacing),
      ExpansionTile(
        title: const Text('Developer'),
        children: [
          SwitchListTile(
            title: const Text('Flutter performance overlay'),
            subtitle: const Text(
              'Session only. Profile builds give representative timings.',
            ),
            value: ref.watch(performanceOverlayProvider),
            onChanged: ref.read(performanceOverlayProvider.notifier).setEnabled,
          ),
          const Text(
            'Whole-app build/raster times by quality at engine report time. Last 120 frames per tier; budget misses use 16.7 ms. Tier transition batches may overlap. Overlay adds overhead. Refresh does not animate the readout.',
          ),
          for (final tier in OrbTier.values) _tierReadout(tier),
          Wrap(
            spacing: AppTheme.smallSpacing,
            children: [
              TextButton(
                onPressed: () => setState(() {}),
                child: const Text('Refresh frame times'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(frameDiagnosticsProvider).reset();
                  setState(() {});
                },
                child: const Text('Reset frame times'),
              ),
            ],
          ),
          const Text(
            'Demo controls · visual only; microphone and audio remain off.',
          ),
          DropdownButtonFormField<OrbState?>(
            key: ValueKey(ref.watch(orbPreviewProvider)),
            initialValue: ref.watch(orbPreviewProvider),
            hint: const Text('Follow chat'),
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Orb visual preview'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Follow chat')),
              ...OrbState.values.map(
                (s) => DropdownMenuItem(value: s, child: Text(s.name)),
              ),
            ],
            onChanged: ref.read(orbPreviewProvider.notifier).select,
          ),
          SwitchListTile(
            title: const Text('Simulate failure on next send'),
            value: ref.watch(demoFailureProvider),
            onChanged: ref.read(demoFailureProvider.notifier).select,
          ),
          const Text(
            'Host CPU/RAM metrics unavailable in this slice. No estimated values shown.',
          ),
        ],
      ),
    ];
  }

  Widget _tierReadout(OrbTier tier) {
    final samples = ref.read(frameDiagnosticsProvider).tiers[tier]!;
    String metric(bool raster) =>
        '${samples.mean(raster: raster)?.toStringAsFixed(1)} ms mean / ${samples.p95(raster: raster)?.toStringAsFixed(1)} ms p95';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${tier.label} tier'),
      subtitle: Text(
        samples.count == 0
            ? 'No measured frames yet.'
            : 'Build: ${metric(false)}\nRaster: ${metric(true)}\n${samples.count} frames · ${samples.budgetMisses} over budget',
      ),
    );
  }
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.onNew, required this.onPage});
  final VoidCallback onNew;
  final void Function(int) onPage;
  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final commands = [
      ('New chat', widget.onNew),
      ('Open Chat', () => widget.onPage(0)),
      ('Open History', () => widget.onPage(1)),
      ('Open Settings', () => widget.onPage(2)),
    ];
    return AlertDialog(
      title: const Text('Commands'),
      content: SizedBox(
        width: AppTheme.readingWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Find a command'),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
            for (final (label, action) in commands.where(
              (c) => c.$1.toLowerCase().contains(_query),
            ))
              ListTile(
                title: Text(label),
                onTap: () {
                  Navigator.pop(context);
                  action();
                },
              ),
            if (commands.every((c) => !c.$1.toLowerCase().contains(_query)))
              const Text('No matching commands.'),
          ],
        ),
      ),
    );
  }
}
