import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';

class TranscriptionMarkdown extends StatelessWidget {
  const new({required this.data, super.key});

  final String data;

  TextStyle? _bold(TextStyle? style) {
    return style?.copyWith(
      fontWeight: FontWeight.w700,
      fontVariations: [
        ...(style.fontVariations ?? const <FontVariation>[]).where(
          (v) => v.axis != 'wght',
        ),
        const FontVariation('wght', 700),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface,
      height: 1.4,
    );

    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: bodyStyle,
        a: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.primary,
        ),
        code: bodyStyle?.copyWith(
          backgroundColor: colorScheme.surfaceContainerHighest,
          fontSize: (bodyStyle.fontSize ?? 14) * 0.9,
        ),
        h1: _bold(
          theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        h2: _bold(
          theme.textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
        ),
        h3: _bold(bodyStyle),
        h4: _bold(bodyStyle),
        h5: _bold(bodyStyle),
        h6: _bold(bodyStyle?.copyWith(color: colorScheme.onSurfaceVariant)),
        em: const TextStyle(fontStyle: FontStyle.italic),
        strong: const TextStyle(
          fontWeight: FontWeight.w700,
          fontVariations: [FontVariation('wght', 700)],
        ),
        del: const TextStyle(decoration: TextDecoration.lineThrough),
        blockquote: bodyStyle?.copyWith(color: colorScheme.onSurfaceVariant),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.5),
              width: 3,
            ),
          ),
        ),
        img: bodyStyle,
        checkbox: bodyStyle?.copyWith(color: colorScheme.primary),
        listBullet: bodyStyle,
        tableHead: _bold(bodyStyle),
        tableBody: bodyStyle,
        tableBorder: TableBorder.all(color: colorScheme.outlineVariant),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
      ),
    );
  }
}
