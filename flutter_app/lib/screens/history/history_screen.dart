import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../models/investigation.dart';
import '../../widgets/staggered_entry.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;

    final historyItems = _getMockHistory();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Investigation History', style: AppTheme.headingMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      '${historyItems.length} investigations completed',
                      style: AppTheme.bodySmall.copyWith(
                        color: textTertiary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Stats row
                  _buildStatsRow(context),
                  const SizedBox(height: 28),

                  // History list
                  StaggeredEntry(
                    staggerDelay: const Duration(milliseconds: 80),
                    children: [
                      for (int i = 0; i < historyItems.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildHistoryCard(context, historyItems[i]),
                        ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final lowRisk = isDark ? AppColors.lowRisk : AppColorsLight.lowRisk;
    final lowRiskBg = isDark ? AppColors.lowRiskBg : AppColorsLight.lowRiskBg;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;

    return Row(
      children: [
        Expanded(child: _statCard(context, '24', 'Total', primary, primaryGlow)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, '8', 'High Risk', highRisk, highRiskBg)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, '14', 'Low Risk', lowRisk, lowRiskBg)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String value, String label, Color color, Color bgColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Text(value, style: AppTheme.headingMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textTertiary
                      : AppColorsLight.textTertiary,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, _HistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;

    final riskColor = _getRiskColor(item.riskLevel, isDark);
    final riskBg = _getRiskBgColor(item.riskLevel, isDark);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pushNamed('/results');
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // File icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: riskBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: riskColor.withOpacity(0.2)),
                ),
                child: Icon(
                  item.mediaType == 'Video'
                      ? Icons.videocam_rounded
                      : Icons.image_rounded,
                  color: riskColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.fileName,
                        style: AppTheme.subtitleMedium.copyWith(color: textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(item.date,
                            style: AppTheme.bodySmall.copyWith(
                                color: textTertiary, fontSize: 11)),
                        const SizedBox(width: 8),
                        Text('•',
                            style: AppTheme.bodySmall.copyWith(color: textMuted)),
                        const SizedBox(width: 8),
                        Text(item.mediaType,
                            style: AppTheme.bodySmall.copyWith(
                                color: textTertiary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),

              // Risk score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.riskScore}',
                      style: AppTheme.headingSmall.copyWith(
                          color: riskColor, fontWeight: FontWeight.w800)),
                  Text('/ 100', style: AppTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(RiskLevel level, bool isDark) {
    if (isDark) {
      switch (level) {
        case RiskLevel.high: return AppColors.highRisk;
        case RiskLevel.medium: return AppColors.mediumRisk;
        case RiskLevel.low: return AppColors.lowRisk;
      }
    } else {
      switch (level) {
        case RiskLevel.high: return AppColorsLight.highRisk;
        case RiskLevel.medium: return AppColorsLight.mediumRisk;
        case RiskLevel.low: return AppColorsLight.lowRisk;
      }
    }
  }

  Color _getRiskBgColor(RiskLevel level, bool isDark) {
    if (isDark) {
      switch (level) {
        case RiskLevel.high: return AppColors.highRiskBg;
        case RiskLevel.medium: return AppColors.mediumRiskBg;
        case RiskLevel.low: return AppColors.lowRiskBg;
      }
    } else {
      switch (level) {
        case RiskLevel.high: return AppColorsLight.highRiskBg;
        case RiskLevel.medium: return AppColorsLight.mediumRiskBg;
        case RiskLevel.low: return AppColorsLight.lowRiskBg;
      }
    }
  }

  List<_HistoryItem> _getMockHistory() {
    return [
      _HistoryItem('suspect_video.mp4', 'Video', 87, RiskLevel.high, 'Aug 29, 2026'),
      _HistoryItem('portrait.jpg', 'Image', 18, RiskLevel.low, 'Aug 29, 2026'),
      _HistoryItem('interview_clip.mp4', 'Video', 54, RiskLevel.medium, 'Aug 28, 2026'),
      _HistoryItem('selfie_check.png', 'Image', 12, RiskLevel.low, 'Aug 28, 2026'),
      _HistoryItem('news_segment.mp4', 'Video', 73, RiskLevel.high, 'Aug 27, 2026'),
      _HistoryItem('profile_photo.jpg', 'Image', 31, RiskLevel.low, 'Aug 27, 2026'),
      _HistoryItem('security_footage.mp4', 'Video', 62, RiskLevel.medium, 'Aug 26, 2026'),
    ];
  }
}

class _HistoryItem {
  final String fileName;
  final String mediaType;
  final int riskScore;
  final RiskLevel riskLevel;
  final String date;

  const _HistoryItem(this.fileName, this.mediaType, this.riskScore, this.riskLevel, this.date);
}
