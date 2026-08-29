import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class AnalysisMetricCard extends StatelessWidget {
  final AnalysisMetric metric;

  const AnalysisMetricCard({
    super.key,
    required this.metric,
  });

  Color get _barColor {
    if (metric.score >= 70) return AppColors.highRisk;
    if (metric.score >= 40) return AppColors.mediumRisk;
    return AppColors.lowRisk;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                metric.icon,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric.name,
                  style: AppTheme.subtitleMedium,
                ),
              ),
              Text(
                '${metric.score}%',
                style: AppTheme.headingSmall.copyWith(
                  color: _barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: metric.score / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            metric.description,
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
