import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/jarvis_app.dart';
import '../../../core/design/app_theme.dart';

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
          child: Row(children: [
            if (wide) NavigationRail(
              selectedIndex: _page,
              onDestinationSelected: (value) => setState(() => _page = value),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Settings')),
              ],
            ),
            Expanded(child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: ListView(padding: const EdgeInsets.all(AppTheme.spacing), children: content),
            ))),
          ]),
        ),
        bottomNavigationBar: wide ? null : NavigationBar(
          selectedIndex: _page,
          onDestinationSelected: (value) => setState(() => _page = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      );
    },
  );

  List<Widget> _home(BuildContext context) => [
    Text('Your space. Your assistant.', style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 16),
    const Card(child: Padding(padding: EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No AI provider connected'),
        SizedBox(height: 8),
        Text('This shell runs locally. Chat arrives in Phase 1b; Ollama setup arrives in Phase 2.'),
        SizedBox(height: 8),
        Text('Microphone off • No requests sent'),
      ],
    ))),
    const SizedBox(height: 24),
    Text('Text input', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text('English and Gujarati text can be entered here. This is a session-only scratchpad; it is not saved.'),
    const SizedBox(height: 12),
    TextField(
      controller: _text,
      minLines: 4,
      maxLines: 12,
      decoration: const InputDecoration(labelText: 'Scratchpad', hintText: 'Hello / નમસ્તે'),
    ),
    const SizedBox(height: 8),
    Align(alignment: Alignment.centerLeft, child: TextButton(
      onPressed: _text.clear,
      child: const Text('Clear scratchpad'),
    )),
  ];

  List<Widget> _settings(BuildContext context) => [
    Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 16),
    DropdownButtonFormField<ThemeMode>(
      initialValue: ref.watch(themeProvider),
      decoration: const InputDecoration(labelText: 'Theme'),
      items: const [
        DropdownMenuItem(value: ThemeMode.system, child: Text('Follow system')),
        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
      ],
      onChanged: (value) {
        if (value != null) ref.read(themeProvider.notifier).select(value);
      },
    ),
    const SizedBox(height: 24),
    const Text('Privacy: this shell stores no data and makes no network requests. Theme and scratchpad reset when the app closes.'),
    const SizedBox(height: 16),
    const Text('Voice is unavailable in this phase. English voice is planned for Phase 5. Gujarati voice requires measured evaluation before it can be offered.'),
    const SizedBox(height: 16),
    const Text('Interface language: English. Gujarati interface localization is planned for a later phase.'),
  ];
}
