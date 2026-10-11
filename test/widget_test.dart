import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/app/jarvis_app.dart';

Future<void> mountShell(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const ProviderScope(child: JarvisApp()));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(390, 900), const Size(1100, 900)]) {
    testWidgets('Home and Settings navigation at ${size.width}px', (
      tester,
    ) async {
      await mountShell(tester, size);
      expect(find.text('No AI provider connected'), findsOneWidget);
      expect(
        find.byType(NavigationRail),
        size.width >= 760 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(NavigationBar),
        size.width < 760 ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Appearance'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Theme menu applies dark, light and system modes', (
    tester,
  ) async {
    await mountShell(tester, const Size(1100, 900));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    for (final entry in [
      ('Dark', ThemeMode.dark, Brightness.dark),
      ('Light', ThemeMode.light, Brightness.light),
      ('Follow system', ThemeMode.system, Brightness.light),
    ]) {
      await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.$1).last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        entry.$2,
      );
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        entry.$3,
      );
    }
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unicode scratchpad survives navigation and clears', (
    tester,
  ) async {
    await mountShell(tester, const Size(1100, 900));
    const text = 'Hello JARVIS! નમસ્તે, આજે મારું કાર્ય પૂર્ણ કરવું છે. 📝';
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      text,
    );
    expect(find.text(text), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      text,
    );
    await tester.ensureVisible(find.text('Clear scratchpad'));
    await tester.tap(find.text('Clear scratchpad'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text(text), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
