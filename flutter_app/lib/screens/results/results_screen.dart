import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_entry.dart';
import '../evidence/evidence_screen.dart';
import '../report/report_screen.dart';

class ResultsScreen extends StatelessWidget {
  final AnalysisResult analysisResult;

  const ResultsScreen({super.key, required this.analysisResult});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final mediumRisk = isDark ? AppColors.mediumRisk : AppColorsLight.mediumRisk;
    final lowRisk = isDark ? AppColors.lowRisk : AppColorsLight.lowRisk;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    // Determine risk colors based on actual score
    Color riskColor;
    Color riskBgColor;
    String riskLabel;
    if (analysisResult.isHighRisk) {
      riskColor = highRisk;
      riskBgColor = highRiskBg;
      riskLabel = 'HIGH RISK';
    } else if (analysisResult.isMediumRisk) {
      riskColor = mediumRisk;
      riskBgColor = mediumRisk.withOpacity(0.1);
      riskLabel = 'MEDIUM RISK';
    } else {
      riskColor = lowRisk;
      riskBgColor = lowRisk.withOpacity(0.1);
      riskLabel = 'LOW RISK';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textSecondary),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text('Investigation Result'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: StaggeredEntry(
                staggerDelay: const Duration(milliseconds: 100),
                children: [
                  const SizedBox(height: 8),

                  // Risk Score Card
                  _buildRiskScoreCard(context, analysisResult, riskColor, riskBgColor),
                  const SizedBox(height: 20),

                  // Assessment callout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: riskBgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: riskColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            analysisResult.isHighRisk
                                ? Icons.warning_amber_rounded
                                : (analysisResult.isMediumRisk
                                    ? Icons.info_outline_rounded
                                    : Icons.check_circle_outline_rounded),
                            color: riskColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _getAssessmentText(analysisResult),
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 14, color: textPrimary, height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Analysis Breakdown
                  Text('Analysis Breakdown', style: AppTheme.headingSmall),
                  const SizedBox(height: 16),

                  // Model score
                  _buildMetricRow(context, 'AI Model Score',
                      '${analysisResult.riskScore} / 100', riskColor),
                  const SizedBox(height: 10),

                  // Faces detected
                  _buildMetricRow(context, 'Faces Detected',
                      '${analysisResult.facesDetected}', textSecondary),
                  const SizedBox(height: 10),

                  // Frames analyzed (for video)
                  if (analysisResult.mediaCategory == 'video')
                    _buildMetricRow(context, 'Frames Analyzed',
                        '${analysisResult.framesAnalyzed}', textSecondary),

                  if (analysisResult.mediaCategory == 'video')
                    const SizedBox(height: 10),

                  // Suspicious frames
                  if (analysisResult.suspiciousFrames.isNotEmpty)
                    _buildMetricRow(context, 'Suspicious Frames',
                        '${analysisResult.suspiciousFrames.length}', highRisk),

                  if (analysisResult.suspiciousFrames.isNotEmpty)
                    const SizedBox(height: 10),

                  // Model info
                  _buildMetricRow(context, 'Model',
                      analysisResult.model, textSecondary),
                  const SizedBox(height: 10),

                  // File hash
                  if (analysisResult.fileHash.isNotEmpty)
                    _buildMetricRow(context, 'File Hash (SHA-256)',
                        '${analysisResult.fileHash.substring(0, 16)}...', textSecondary),

                  const SizedBox(height: 28),

                  // CTA buttons
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'View Evidence',
                                icon: Icons.search_rounded,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EvidenceScreen(analysisResult: analysisResult),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Full Report',
                                icon: Icons.description_rounded,
                                isOutlined: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReportScreen(analysisResult: analysisResult),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            PrimaryButton(
                              label: 'View Evidence',
                              icon: Icons.search_rounded,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EvidenceScreen(analysisResult: analysisResult),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Full Report',
                              icon: Icons.description_rounded,
                              isOutlined: true,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReportScreen(analysisResult: analysisResult),
                                  ),
                                );
                              },
                            ),
                          ],
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

  String _getAssessmentText(AnalysisResult result) {
    if (result.isHighRisk) {
      return 'Multiple signals associated with digital manipulation were detected. Score: ${result.riskScore}/100.';
    } else if (result.isMediumRisk) {
      return 'Some indicators of potential manipulation detected. Manual verification recommended. Score: ${result.riskScore}/100.';
    } else if (result.facesDetected == 0) {
      return result.message.isNotEmpty
          ? result.message
          : 'No faces detected. Unable to perform manipulation analysis.';
    } else {
      return 'Analysis indicates the media is likely authentic. Score: ${result.riskScore}/100.';
    }
  }

  Widget _buildRiskScoreCard(BuildContext context, AnalysisResult result,
      Color riskColor, Color riskBgColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text('MANIPULATION RISK SCORE',
              style: AppTheme.labelMedium.copyWith(
                  color: textMuted, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 16),

          // Score circle
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140, height: 140,
                  child: CircularProgressIndicator(
                    value: result.riskScore / 100,
                    strokeWidth: 10,
                    backgroundColor: riskColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${result.riskScore}',
                        style: AppTheme.headingLarge.copyWith(
                            color: riskColor, fontSize: 42, fontWeight: FontWeight.w800)),
                    Text('/100',
                        style: AppTheme.bodySmall.copyWith(color: textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Risk level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: riskBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: riskColor.withOpacity(0.3)),
            ),
            child: Text(
              result.isHighRisk ? 'HIGH RISK' :
              (result.isMediumRisk ? 'MEDIUM RISK' : 'LOW RISK'),
              style: AppTheme.labelMedium.copyWith(
                  color: riskColor, letterSpacing: 1.5, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium.copyWith(color: textMuted, fontSize: 14)),
          Text(value, style: AppTheme.bodyLarge.copyWith(
              color: valueColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
