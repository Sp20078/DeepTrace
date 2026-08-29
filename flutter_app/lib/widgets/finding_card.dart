import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class FindingCard extends StatelessWidget {
  final Finding finding;

  const FindingCard({
    super.key,
    required this.finding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: finding.isCritical
              ? AppColors.highRisk.withValues(alpha: 0.3)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: finding.isCritical
                  ? AppColors.highRiskBg
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${finding.number}',
                style: AppTheme.labelMedium.copyWith(
                  color: finding.isCritical
                      ? AppColors.highRisk
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Finding text
          Expanded(
            child: Text(
              finding.description,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          if (finding.isCritical) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.highRiskBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'CRITICAL',
                style: AppTheme.labelMedium.copyWith(
                  color: AppColors.highRisk,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
