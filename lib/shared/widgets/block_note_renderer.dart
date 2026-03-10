import 'dart:convert';
import 'package:flutter/material.dart';

/// Renders a BlockNote JSON string (used by Twenty CRM's bodyV2.blocknote field)
/// as native Flutter widgets, without any external dependency.
class BlockNoteRenderer extends StatelessWidget {
  final String json;
  final bool compact;

  const BlockNoteRenderer({super.key, required this.json, this.compact = false});

  @override
  Widget build(BuildContext context) {
    List<dynamic> blocks;
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        blocks = decoded;
      } else {
        return _fallback(context, json);
      }
    } catch (_) {
      return _fallback(context, json);
    }

    if (blocks.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    int numberedIndex = 1;

    for (final block in blocks) {
      if (block is! Map<String, dynamic>) continue;
      final type = block['type'] as String? ?? 'paragraph';
      final props = block['props'] as Map<String, dynamic>? ?? {};
      final content = block['content'] as List<dynamic>? ?? [];
      final children = block['children'] as List<dynamic>? ?? [];

      // Reset numbered list counter if not a numbered list item
      if (type != 'numberedListItem') numberedIndex = 1;

      Widget? w = _buildBlock(context, type, props, content, numberedIndex);
      if (type == 'numberedListItem') numberedIndex++;

      if (w == null) continue;

      // Render children recursively (indented)
      if (children.isNotEmpty) {
        final childWidgets = children
            .whereType<Map<String, dynamic>>()
            .map((c) => Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: BlockNoteRenderer(json: jsonEncode([c]), compact: compact),
                ))
            .toList();
        widgets.add(w);
        widgets.addAll(childWidgets);
      } else {
        widgets.add(w);
      }

      if (!compact) widgets.add(const SizedBox(height: 2));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget? _buildBlock(
    BuildContext context,
    String type,
    Map<String, dynamic> props,
    List<dynamic> content,
    int numberedIndex,
  ) {
    final theme = Theme.of(context);

    switch (type) {
      case 'heading':
        final level = (props['level'] as num?)?.toInt() ?? 1;
        final style = level == 1
            ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            : level == 2
                ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);
        final padding = level == 1
            ? const EdgeInsets.only(top: 12, bottom: 4)
            : const EdgeInsets.only(top: 8, bottom: 2);
        return Padding(
          padding: padding,
          child: _buildInlineText(content, style ?? const TextStyle()),
        );

      case 'bulletListItem':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Text('•', style: TextStyle(fontSize: 14)),
              ),
              Expanded(child: _buildInlineText(content, theme.textTheme.bodyMedium ?? const TextStyle())),
            ],
          ),
        );

      case 'numberedListItem':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0, right: 8),
                child: Text('$numberedIndex.', style: theme.textTheme.bodyMedium),
              ),
              Expanded(child: _buildInlineText(content, theme.textTheme.bodyMedium ?? const TextStyle())),
            ],
          ),
        );

      case 'checkListItem':
        final checked = props['checked'] == true;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: checked ? Colors.green : null,
                ),
              ),
              Expanded(
                child: _buildInlineText(
                  content,
                  (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                    decoration: checked ? TextDecoration.lineThrough : null,
                    color: checked ? Colors.grey : null,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'codeBlock':
        final codeText = _extractPlainText(content);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          width: double.infinity,
          child: Text(codeText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        );

      case 'image':
        final url = props['url'] as String?;
        if (url == null || url.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        );

      case 'divider':
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(),
        );

      case 'paragraph':
      default:
        if (content.isEmpty) return compact ? null : const SizedBox(height: 4);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: _buildInlineText(content, theme.textTheme.bodyMedium ?? const TextStyle()),
        );
    }
  }

  Widget _buildInlineText(List<dynamic> content, TextStyle baseStyle) {
    if (content.isEmpty) return const SizedBox.shrink();

    final spans = <InlineSpan>[];
    for (final item in content) {
      if (item is! Map<String, dynamic>) continue;
      final type = item['type'] as String? ?? 'text';

      if (type == 'text') {
        final text = item['text'] as String? ?? '';
        if (text.isEmpty) continue;
        final styles = item['styles'] as Map<String, dynamic>? ?? {};
        spans.add(TextSpan(text: text, style: _applyStyles(baseStyle, styles)));
      } else if (type == 'link') {
        final href = item['href'] as String? ?? '';
        final linkContent = item['content'] as List<dynamic>? ?? [];
        final linkText = _extractPlainText(linkContent);
        spans.add(TextSpan(
          text: linkText.isNotEmpty ? linkText : href,
          style: baseStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ));
      }
    }

    if (spans.isEmpty) return const SizedBox.shrink();
    return RichText(text: TextSpan(children: spans), textScaler: TextScaler.noScaling);
  }

  TextStyle _applyStyles(TextStyle base, Map<String, dynamic> styles) {
    var style = base;
    if (styles['bold'] == true) style = style.copyWith(fontWeight: FontWeight.bold);
    if (styles['italic'] == true) style = style.copyWith(fontStyle: FontStyle.italic);
    if (styles['underline'] == true) style = style.copyWith(decoration: TextDecoration.underline);
    if (styles['strikethrough'] == true) style = style.copyWith(decoration: TextDecoration.lineThrough);
    if (styles['code'] == true) {
      style = style.copyWith(fontFamily: 'monospace', backgroundColor: Colors.grey.shade200, fontSize: (style.fontSize ?? 14) - 1);
    }
    final textColor = styles['textColor'];
    if (textColor is String && textColor != 'default') {
      style = style.copyWith(color: _colorFromName(textColor));
    }
    final bgColor = styles['backgroundColor'];
    if (bgColor is String && bgColor != 'default') {
      style = style.copyWith(backgroundColor: _colorFromName(bgColor));
    }
    return style;
  }

  Color? _colorFromName(String name) => switch (name) {
    'red' => Colors.red,
    'blue' => Colors.blue,
    'green' => Colors.green,
    'yellow' => Colors.amber,
    'orange' => Colors.orange,
    'purple' => Colors.purple,
    'pink' => Colors.pink,
    'gray' || 'grey' => Colors.grey,
    _ => null,
  };

  String _extractPlainText(List<dynamic> content) {
    return content
        .whereType<Map<String, dynamic>>()
        .map((e) => e['text'] as String? ?? '')
        .join();
  }

  Widget _fallback(BuildContext context, String raw) {
    return Text(raw, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey));
  }
}
