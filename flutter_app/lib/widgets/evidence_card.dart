import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class EvidenceCard extends StatelessWidget {
  final RecentInvestigation investigation;
  final VoidCallback? onTap;

  const EvidenceCard({
    super.key,
    required this.investigation,
    this.onTap,
  });

  Color get _riskColor {
    switch (investigation.riskLevel) {
      case RiskLevel.high:
        return AppColors.highRisk;
      case RiskLevel.medium:
        return AppColors.mediumRisk;
      case RiskLevel.low:
        return AppColors.lowRisk;
    }
  }

  Color get _riskBgColor {
    switch (investigation.riskLevel) {
      case RiskLevel.high:
        return AppColors.highRiskBg;
      case RiskLevel.medium:
        return AppColors.mediumRiskBg;
      case RiskLevel.low:
        return AppColors.lowRiskBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            // File icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _riskBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                investigation.fileName.endsWith('.mp4') ||
                        investigation.fileName.endsWith('.mov')
                    ? Icons.videocam_rounded
                    : Icons.image_rounded,
                color: _riskColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investigation.fileName,
                    style: AppTheme.subtitleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _riskLabel,
                    style: AppTheme.labelMedium.copyWith(color: _riskColor),
                  ),
                ],
              ),
            ),

            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${investigation.riskScore}',
                  style: AppTheme.headingSmall.copyWith(
                    color: _riskColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '/ 100',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _riskLabel {
    switch (investigation.riskLevel) {
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.low:
        return 'LOW RISK';
    }
  }
}
