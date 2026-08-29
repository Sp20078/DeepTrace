import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class RiskScoreCard extends StatelessWidget {
  final int score;
  final RiskLevel riskLevel;
  final String label;

  const RiskScoreCard({
    super.key,
    required this.score,
    required this.riskLevel,
    required this.label,
  });

  Color get _riskColor {
    switch (riskLevel) {
      case RiskLevel.high:
        return AppColors.highRisk;
      case RiskLevel.medium:
        return AppColors.mediumRisk;
      case RiskLevel.low:
        return AppColors.lowRisk;
    }
  }

  Color get _riskBgColor {
    switch (riskLevel) {
      case RiskLevel.high:
        return AppColors.highRiskBg;
      case RiskLevel.medium:
        return AppColors.mediumRiskBg;
      case RiskLevel.low:
        return AppColors.lowRiskBg;
    }
  }

  String get _riskLabel {
    switch (riskLevel) {
      case RiskLevel.high:
        return '⚠ HIGH RISK';
      case RiskLevel.medium:
        return '⚡ MEDIUM RISK';
      case RiskLevel.low:
        return '✓ LOW RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _riskColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Risk badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _riskBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _riskColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _riskLabel,
              style: AppTheme.labelLarge.copyWith(
                color: _riskColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: _riskColor,
                  height: 1,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ 100',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Label
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
