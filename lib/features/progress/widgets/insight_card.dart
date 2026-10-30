import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final highlightWord = _highlightWord(description);

    return Container(
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: cs.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMd.copyWith(color: cs.primary),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
                    children: _buildTextSpans(description, highlightWord, cs),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _highlightWord(String text) {
    if (text.toLowerCase().contains('wednesdays')) return 'Wednesdays';
    if (text.toLowerCase().contains('mid-week')) return 'mid-week';
    return null;
  }

  List<TextSpan> _buildTextSpans(
      String text, String? highlightWord, ColorScheme cs) {
    if (highlightWord == null) return [TextSpan(text: text)];

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlightWord.toLowerCase();
    final start = lowerText.indexOf(lowerHighlight);
    if (start < 0) return [TextSpan(text: text)];

    final end = start + highlightWord.length;
    return [
      TextSpan(text: text.substring(0, start)),
      TextSpan(
        text: text.substring(start, end),
        style: AppTextStyles.bodyMd.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      TextSpan(text: text.substring(end)),
    ];
  }
}
