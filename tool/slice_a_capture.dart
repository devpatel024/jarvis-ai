// Native profile capture of actual JarvisApp, with bounded synthetic viewports.
// flutter run -d linux --profile --no-pub -t tool/slice_a_capture.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/app/jarvis_app.dart';
import 'package:jarvis/core/design/app_theme.dart';
import 'package:jarvis/core/design/motion_settings.dart';
import 'package:jarvis/core/developer/performance_settings.dart';
import 'package:jarvis/features/chat/data/mock_provider.dart';
import 'package:jarvis/features/chat/presentation/chat_controller.dart';

final captureKey = GlobalKey();
final harnessKey = GlobalKey<_CaptureHarnessState>();
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(_CaptureHarness(key: harnessKey));
  unawaited(_capture());
}

Future<void> _capture() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  final directory = Directory('docs/screenshots')..createSync(recursive: true);
  for (final palette in AppPalette.values) {
    for (final brightness in Brightness.values) {
      for (final width in [1200.0, if (palette == AppPalette.aurora) 390.0]) {
        for (final conversation in [false, true]) {
          await harnessKey.currentState!.scene(
            palette,
            brightness,
            width,
            conversation,
          );
          await Future<void>.delayed(const Duration(milliseconds: 1500));
          await WidgetsBinding.instance.endOfFrame;
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final name =
              '${palette.name}-${brightness.name}-${width.toInt()}-${conversation ? 'chat' : 'empty'}.png';
          await File(
            '${directory.path}/$name',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
          stdout.writeln('JARVIS_CAPTURE $name');
        }
      }
    }
  }
  for (final brightness in Brightness.values) {
    await harnessKey.currentState!.scene(
      AppPalette.aurora,
      brightness,
      390,
      false,
      scale: 2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    // Show the suggestions fully after scrolling the empty state at large text.
    final scrollable = findScrollable(captureKey.currentContext!);
    scrollable?.position.jumpTo(scrollable.position.maxScrollExtent);
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '${directory.path}/aurora-${brightness.name}-390-large-text-suggestions.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  }
  exit(0);
}

ScrollableState? findScrollable(BuildContext context) {
  ScrollableState? result;
  void visit(Element element) {
    if (result != null) return;
    if (element is StatefulElement && element.state is ScrollableState) {
      final state = element.state as ScrollableState;
      if (state.position.axis == Axis.vertical) result = state;
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
  return result;
}

class _CaptureHarness extends StatefulWidget {
  const _CaptureHarness({super.key});
  @override
  State<_CaptureHarness> createState() => _CaptureHarnessState();
}

class _CaptureHarnessState extends State<_CaptureHarness> {
  ProviderContainer _container = ProviderContainer();
  double _width = 1200;
  double _scale = 1;
  int _scene = 0;
  Future<void> scene(
    AppPalette palette,
    Brightness brightness,
    double width,
    bool conversation, {
    double scale = 1,
  }) async {
    final previous = _container;
    final next = ProviderContainer(
      overrides: [
        llmProvider.overrideWithValue(
          const MockProvider(
            firstTokenDelay: Duration.zero,
            tokenDelay: Duration.zero,
          ),
        ),
      ],
    );
    next.read(paletteProvider.notifier).select(palette);
    next
        .read(themeProvider.notifier)
        .select(
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        );
    next.read(reduceMotionProvider.notifier).setReduced(true);
    next.read(qualityProvider.notifier).select(OrbTier.lite);
    if (conversation) {
      await next
          .read(chatProvider.notifier)
          .send('નમસ્તે! મારા દિવસનું આયોજન કરો.');
      await next.read(chatProvider.notifier).send('Show a code example');
    }
    setState(() {
      _container = next;
      _width = width;
      _scale = scale;
      _scene++;
    });
    await WidgetsBinding.instance.endOfFrame;
    previous.dispose();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: OverflowBox(
        minWidth: _width,
        maxWidth: _width,
        minHeight: 900,
        maxHeight: 900,
        child: RepaintBoundary(
          key: captureKey,
          child: SizedBox(
            width: _width,
            height: 900,
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(_width, 900),
                textScaler: TextScaler.linear(_scale),
              ),
              child: UncontrolledProviderScope(
                key: ValueKey(_scene),
                container: _container,
                child: const JarvisApp(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
