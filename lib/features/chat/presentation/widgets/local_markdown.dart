import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_theme.dart';

/// Deliberately small offline subset: paragraphs, headings, lists, emphasis,
/// inline code and fenced code. No HTML, remote images or executable content.
class LocalMarkdown extends StatelessWidget {
  const LocalMarkdown({super.key, required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    final lines = text.split('\n');
    final buffer = <String>[];
    String? language;
    void flushCode() {
      final code = buffer.join('\n');
      buffer.clear();
      blocks.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
          padding: const EdgeInsets.all(AppTheme.messagePadding),
          decoration: BoxDecoration(
            color: JarvisColors.of(context).background,
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      language!.isEmpty ? 'code' : language,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy code',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
                        );
                      }
                    },
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontFamilyFallback: const ['NotoSansGujarati'],
                    color: JarvisColors.of(context).ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (final line in lines) {
      if (line.startsWith('```')) {
        if (language == null) {
          language = line.substring(3).trim();
        } else {
          flushCode();
          language = null;
        }
      } else if (language != null) {
        buffer.add(line);
      } else {
        final heading = RegExp(r'^(#{1,3})\s+').firstMatch(line);
        final value = heading != null
            ? line.substring(heading.end)
            : line.replaceFirst(RegExp(r'^[-*]\s+'), '• ');
        final style =
            (heading != null
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyLarge)!
                .copyWith(color: color, height: 1.5);
        final spans = <TextSpan>[];
        final pattern = RegExp(r'(`[^`]+`|\*\*[^*]+\*\*|\*[^*]+\*)');
        var end = 0;
        for (final match in pattern.allMatches(value)) {
          spans.add(TextSpan(text: value.substring(end, match.start)));
          final token = match.group(0)!;
          final code = token.startsWith('`'), bold = token.startsWith('**');
          final edge = bold ? 2 : 1;
          spans.add(
            TextSpan(
              text: token.substring(edge, token.length - edge),
              style: TextStyle(
                fontFamily: code ? 'JetBrainsMono' : null,
                fontWeight: bold ? FontWeight.bold : null,
                fontStyle: !code && !bold ? FontStyle.italic : null,
              ),
            ),
          );
          end = match.end;
        }
        spans.add(TextSpan(text: value.substring(end)));
        blocks.add(
          SelectableText.rich(TextSpan(style: style, children: spans)),
        );
      }
    }
    if (language != null) flushCode();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
