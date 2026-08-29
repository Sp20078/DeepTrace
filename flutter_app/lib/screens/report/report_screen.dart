import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/investigation.dart';
import '../../widgets/finding_card.dart';
import '../../widgets/primary_button.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final investigation = MockData.demoInvestigation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Forensic Report'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Report header card
              _buildReportHeader(investigation),
              const SizedBox(height: 24),

              // Key Findings
              Text('Key Findings', style: AppTheme.headingSmall),
              const SizedBox(height: 16),
              ...investigation.findings.map(
                (finding) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FindingCard(finding: finding),
                ),
              ),

              const SizedBox(height: 28),

              // Conclusion
              _buildConclusion(investigation),
              const SizedBox(height: 24),

              // Disclaimer
              _buildDisclaimer(),
              const SizedBox(height: 28),

              // Generate Report button
              PrimaryButton(
                label: 'Generate Report',
                icon: Icons.file_download_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Report generated successfully!',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader(Investigation investigation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Forensic Investigation Report',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info rows
          _infoRow('Investigation ID', investigation.id),
          _infoRow('File', investigation.fileName),
          _infoRow('Media Type', investigation.mediaType),
          _infoRow('Analyzed Frames', '${investigation.analyzedFrames}'),
          const Divider(height: 24, color: AppColors.cardBorder),
          _infoRow(
            'Overall Risk',
            '${investigation.riskScore} / 100',
            valueColor: AppColors.highRisk,
          ),
          _infoRow(
            'Assessment',
            investigation.assessment,
            valueColor: AppColors.highRisk,
            isBadge: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor, bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: isBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.highRiskBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      value,
                      style: AppTheme.labelMedium.copyWith(
                        color: valueColor ?? AppColors.textPrimary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: AppTheme.bodyLarge.copyWith(
                      color: valueColor ?? AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConclusion(Investigation investigation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conclusion',
            style: AppTheme.subtitleMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"${investigation.conclusion}"',
            style: AppTheme.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.disclaimer,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
