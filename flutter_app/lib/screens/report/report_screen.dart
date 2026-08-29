import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../models/investigation.dart';
import '../../widgets/finding_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_entry.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final investigation = MockData.demoInvestigation;
    final padding = ResponsiveWrapper.padding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Forensic Report'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: StaggeredEntry(
                staggerDelay: const Duration(milliseconds: 80),
                children: [
                  const SizedBox(height: 16),
                  _buildReportHeader(context, investigation),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.primary : AppColorsLight.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Key Findings', style: AppTheme.headingSmall),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...investigation.findings.map(
                    (finding) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FindingCard(finding: finding),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildConclusion(context, investigation),
                  const SizedBox(height: 24),
                  _buildDisclaimer(context),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Generate Report',
                    icon: Icons.file_download_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text('Report generated successfully!',
                                  style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
                            ],
                          ),
                          backgroundColor: isDark ? AppColors.success : AppColorsLight.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader(BuildContext context, Investigation investigation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.06), blurRadius: 20, spreadRadius: -4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description_rounded, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forensic Investigation Report',
                        style: AppTheme.headingSmall.copyWith(color: primary)),
                    const SizedBox(height: 2),
                    Text('DEEPTRACE Analysis System',
                        style: AppTheme.bodySmall.copyWith(color: textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _infoRow('Investigation ID', investigation.id, textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('File', investigation.fileName, textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('Media Type', investigation.mediaType, textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('Analyzed Frames', '${investigation.analyzedFrames}', textTertiary: textTertiary, textPrimary: textPrimary),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: cardBorder),
          ),
          _infoRow('Overall Risk', '${investigation.riskScore} / 100',
              valueColor: highRisk, textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('Assessment', investigation.assessment,
              valueColor: highRisk, isBadge: true, textTertiary: textTertiary,
              textPrimary: textPrimary, highRiskBg: highRiskBg, highRisk: highRisk),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor, bool isBadge = false,
      required Color textTertiary, required Color textPrimary,
      Color? highRiskBg, Color? highRisk}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTheme.bodyMedium.copyWith(color: textTertiary, fontSize: 13)),
          ),
          Expanded(
            child: isBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: highRiskBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (highRisk ?? valueColor ?? textPrimary).withOpacity(0.2)),
                    ),
                    child: Text(
                      value,
                      style: AppTheme.labelMedium.copyWith(
                        color: valueColor ?? textPrimary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: AppTheme.bodyLarge.copyWith(
                      color: valueColor ?? textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConclusion(BuildContext context, Investigation investigation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, color: primary, size: 20),
              const SizedBox(width: 10),
              Text('Conclusion',
                  style: AppTheme.subtitleMedium.copyWith(color: primary)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"${investigation.conclusion}"',
            style: AppTheme.bodyLarge.copyWith(
              color: textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.disclaimer,
              style: AppTheme.bodySmall.copyWith(color: textMuted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
