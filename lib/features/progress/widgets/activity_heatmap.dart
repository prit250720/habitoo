import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../providers/progress_provider.dart';

class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.heatmapDays,
    required this.consistencyPercent,
    required this.activeDays,
  });

  final List<HeatmapDay> heatmapDays;
  final int consistencyPercent;
  final int activeDays;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final visibleDays = heatmapDays.isEmpty
        ? List.generate(30, (index) {
            final intensity = index % HeatmapIntensity.values.length;
            return HeatmapDay(
              dayIndex: index + 1,
              intensity: HeatmapIntensity.values[intensity],
              completedHabits: 1 + (index % 6),
            );
          })
        : heatmapDays.length > 30
            ? heatmapDays.take(30).toList()
            : heatmapDays;

    // Build legend and cell colors from the live colorScheme so they
    // adapt to dark mode automatically.
    final legendColors = _legendColors(cs);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
        border: Border.all(color: cs.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Heatmap',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: cs.onSurface,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your consistency over the last 30 days',
                      style: AppTextStyles.labelSm.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    'Less',
                    style: AppTextStyles.labelSm.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...legendColors.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: entry.value,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    'More',
                    style: AppTextStyles.labelSm.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: visibleDays.map((day) {
              return Tooltip(
                message: 'Day ${day.dayIndex}: ${day.completedHabits} habits',
                child: Container(
                  decoration: BoxDecoration(
                    color: _heatmapColor(day.intensity, cs),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Divider(color: cs.surfaceContainerHighest),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _summaryItem(cs, 'Consistency', '$consistencyPercent%'),
                  const SizedBox(width: 24),
                  _summaryItem(cs, 'Active Days', '$activeDays/30'),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'Download Report',
                  style: AppTextStyles.labelMd.copyWith(color: cs.onPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, Color> _legendColors(ColorScheme cs) => {
        'low': cs.surfaceContainerHighest,
        'medium': cs.primaryFixed,
        'high': cs.primaryContainer,
        'top': cs.primary,
      };

  Widget _summaryItem(ColorScheme cs, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.bodyLg.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Color _heatmapColor(HeatmapIntensity intensity, ColorScheme cs) {
    switch (intensity) {
      case HeatmapIntensity.low:
        return cs.surfaceContainerHighest;
      case HeatmapIntensity.medium:
        return cs.primaryFixed;
      case HeatmapIntensity.high:
        return cs.primaryContainer;
      case HeatmapIntensity.top:
        return cs.primary;
    }
  }
}
