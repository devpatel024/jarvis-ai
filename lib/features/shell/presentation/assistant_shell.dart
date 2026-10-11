import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/jarvis_app.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/developer/performance_settings.dart';
import '../../../core/design/motion_settings.dart';
import '../../chat/presentation/chat_screen.dart';

class AssistantShell extends ConsumerStatefulWidget {
  const AssistantShell({super.key});
  @override
  ConsumerState<AssistantShell> createState() => _AssistantShellState();
}

class _AssistantShellState extends ConsumerState<AssistantShell> {
  final _text = TextEditingController();
  int _page = 0;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final content = _page == 0 ? _home(context) : _settings(context);
      return Scaffold(
        appBar: AppBar(title: const Text('JARVIS')),
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _page,
                  onDestinationSelected: (value) =>
                      setState(() => _page = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: Text('Settings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      label: Text('Chat'),
                    ),
                  ],
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: _page == 2
                        ? const ChatScreen()
                        : ListView(
                            padding: const EdgeInsets.all(AppTheme.spacing),
                            children: content,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _page,
                onDestinationSelected: (value) => setState(() => _page = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    label: 'Chat',
                  ),
                ],
              ),
      );
    },
  );

  List<Widget> _home(BuildContext context) => [
    Text(
      'Your space. Your assistant.',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    const SizedBox(height: 16),
    const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No AI provider connected'),
            SizedBox(height: 8),
            Text(
              'This shell runs locally. Open Chat for the labeled demo. Ollama setup arrives in Phase 2.',
            ),
            SizedBox(height: 8),
            Text('Microphone off • No requests sent'),
          ],
        ),
      ),
    ),
    const SizedBox(height: 24),
    Text('Text input', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text(
      'English and Gujarati text can be entered here. This is a session-only scratchpad; it is not saved.',
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _text,
      minLines: 4,
      maxLines: 12,
      decoration: const InputDecoration(
        labelText: 'Scratchpad',
        hintText: 'Hello / નમસ્તે',
      ),
    ),
    const SizedBox(height: 8),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: _text.clear,
        child: const Text('Clear scratchpad'),
      ),
    ),
  ];

  Widget _tierReadout(OrbTier tier) {
    final samples = ref.read(frameDiagnosticsProvider).tiers[tier]!;
    String metric(bool raster) =>
        '${samples.mean(raster: raster)?.toStringAsFixed(1)} ms mean / '
        '${samples.p95(raster: raster)?.toStringAsFixed(1)} ms p95';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${tier == OrbTier.animated ? 'Animated' : 'Simple'} orb tier',
      ),
      subtitle: Text(
        samples.count == 0
            ? 'No measured frames yet. Open Chat, then return here and refresh.'
            : 'Build: ${metric(false)}\nRaster: ${metric(true)}\n'
                  '${samples.count} frames • ${samples.budgetMisses} over budget',
      ),
    );
  }

  List<Widget> _settings(BuildContext context) => [
    Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 16),
    DropdownButtonFormField<ThemeMode>(
      isExpanded: true,
      initialValue: ref.watch(themeProvider),
      decoration: const InputDecoration(labelText: 'Theme'),
      items: const [
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Text(
            'Follow system',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
      ],
      onChanged: (value) {
        if (value != null) ref.read(themeProvider.notifier).select(value);
      },
    ),
    const SizedBox(height: 24),
    SwitchListTile(
      title: const Text('Reduce motion'),
      subtitle: const Text(
        'Also respects the OS animation accessibility setting.',
      ),
      value: ref.watch(reduceMotionProvider),
      onChanged: ref.read(reduceMotionProvider.notifier).setReduced,
    ),
    const Text(
      'Privacy: this shell stores no data and makes no network requests. Appearance settings and scratchpad reset when the app closes.',
    ),
    const SizedBox(height: 16),
    const Text(
      'Voice is unavailable in this phase. English voice evaluation is planned for Phase 1b.3. Gujarati voice requires measured evaluation before it can be offered.',
    ),
    const SizedBox(height: 16),
    const Text(
      'Interface language: English. Gujarati interface localization is planned for a later phase.',
    ),
    const SizedBox(height: AppTheme.spacing),
    Text('Developer', style: Theme.of(context).textTheme.titleLarge),
    SwitchListTile(
      title: const Text('Flutter performance overlay'),
      subtitle: const Text(
        'Session only. Use a profile build for representative timings.',
      ),
      value: ref.watch(performanceOverlayProvider),
      onChanged: ref.read(performanceOverlayProvider.notifier).setEnabled,
    ),
    const Text(
      'Whole-app build/raster times while Chat is open, grouped by orb tier when the engine reports them. Last 120 frames per tier; 16.7 ms budget. Overlay adds overhead. Static tiers only produce frames when content changes.',
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
  ];
}
