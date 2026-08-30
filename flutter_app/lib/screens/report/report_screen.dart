import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_entry.dart';
import '../../widgets/confetti_overlay.dart';

class ReportScreen extends StatefulWidget {
  final AnalysisResult? analysisResult;

  const ReportScreen({super.key, this.analysisResult});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _showConfetti = false;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.analysisResult!;
    final padding = ResponsiveWrapper.padding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Forensic Report'),
            backgroundColor: bg,
            elevation: 0,
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: StaggeredEntry(
                    staggerDelay: const Duration(milliseconds: 80),
                    children: [
                      const SizedBox(height: 16),
                      _buildReportHeader(context, result),
                      const SizedBox(height: 28),

                      // Key Findings
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
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

                      if (result.findings.isNotEmpty)
                        ...result.findings.map(
                          (finding) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildFindingCard(context, finding),
                          ),
                        )
                      else
                        _buildNoFindingsCard(context),

                      const SizedBox(height: 28),

                      // Suspicious timestamps
                      if (result.suspiciousFrames.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.highRisk : AppColorsLight.highRisk,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Suspicious Timestamps', style: AppTheme.headingSmall),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTimestampsList(context),
                        const SizedBox(height: 28),
                      ],

                      // Conclusion
                      _buildConclusion(context, result),
                      const SizedBox(height: 24),
                      _buildDisclaimer(context),
                      const SizedBox(height: 28),

                      PrimaryButton(
                        label: _isGenerating ? 'Generating...' : 'Generate Report',
                        icon: _isGenerating ? Icons.hourglass_top_rounded : Icons.file_download_rounded,
                        onPressed: _isGenerating ? null : () => _onGenerateReport(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_showConfetti)
            ConfettiOverlay(
              show: _showConfetti,
              onComplete: () {
                if (mounted) setState(() => _showConfetti = false);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _onGenerateReport() async {
    if (_isGenerating) return;
    
    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = widget.analysisResult!;

    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text('Generating PDF report...',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
            ],
          ),
          backgroundColor: isDark ? AppColors.primary : AppColorsLight.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 30),
        ),
      );

      // Download PDF from backend
      final reportUrl = ApiService.getReportUrl(result.analysisId);
      final response = await http.get(Uri.parse(reportUrl)).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Timeout generating report'),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        // Save to file
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/DeepTrace_Report_${result.analysisId.substring(0, 12)}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        // Show success with confetti
        setState(() => _showConfetti = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Report generated!',
                          style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
                      Text('Saved to: ${file.path}',
                          style: AppTheme.bodySmall.copyWith(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: isDark ? AppColors.success : AppColorsLight.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Failed to generate report',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white)),
            ],
          ),
          backgroundColor: isDark ? AppColors.highRisk : AppColorsLight.highRisk,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Widget _buildReportHeader(BuildContext context, AnalysisResult result) {
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

    final riskLabel = result.isHighRisk ? 'HIGH RISK' :
        (result.isMediumRisk ? 'MEDIUM RISK' : 'LOW RISK');
    final riskColor = result.isHighRisk ? highRisk :
        (result.isMediumRisk
            ? (isDark ? AppColors.mediumRisk : AppColorsLight.mediumRisk)
            : (isDark ? AppColors.lowRisk : AppColorsLight.lowRisk));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.06), blurRadius: 20, spreadRadius: -4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
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
          _infoRow('Investigation ID', result.analysisId.substring(0, 12).toUpperCase(),
              textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('File', result.filename,
              textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('Media Type', result.mediaCategory.toUpperCase(),
              textTertiary: textTertiary, textPrimary: textPrimary),
          if (result.mediaCategory == 'video')
            _infoRow('Frames Analyzed', '${result.framesAnalyzed}',
                textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('Faces Detected', '${result.facesDetected}',
              textTertiary: textTertiary, textPrimary: textPrimary),
          if (result.fileHash.isNotEmpty)
            _infoRow('SHA-256', '${result.fileHash.substring(0, 32)}...',
                textTertiary: textTertiary, textPrimary: textPrimary),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: cardBorder),
          ),
          _infoRow('Model', result.model,
              textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('Overall Risk', '${result.riskScore} / 100',
              valueColor: riskColor, textTertiary: textTertiary, textPrimary: textPrimary),
          _infoRow('Assessment', riskLabel,
              valueColor: riskColor, isBadge: true,
              textTertiary: textTertiary, textPrimary: textPrimary,
              highRiskBg: highRiskBg, highRisk: riskColor),
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
                      border: Border.all(
                          color: (highRisk ?? valueColor ?? textPrimary).withOpacity(0.2)),
                    ),
                    child: Text(value, style: AppTheme.labelMedium.copyWith(
                        color: valueColor ?? textPrimary, fontSize: 12, letterSpacing: 0.5)),
                  )
                : Text(value, style: AppTheme.bodyLarge.copyWith(
                    color: valueColor ?? textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingCard(BuildContext context, dynamic finding) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final severity = finding['severity'] ?? 'info';
    final isCritical = severity == 'critical';
    final description = finding['description'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4, height: 40,
            decoration: BoxDecoration(
              color: isCritical ? highRisk : (isDark ? AppColors.primary : AppColorsLight.primary),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCritical)
                  Text('CRITICAL', style: AppTheme.labelMedium.copyWith(
                      color: highRisk, fontSize: 10, letterSpacing: 1)),
                Text(description,
                    style: AppTheme.bodyLarge.copyWith(
                        color: textPrimary, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFindingsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: success, size: 32),
          const SizedBox(height: 10),
          Text('No critical findings',
              style: AppTheme.bodyLarge.copyWith(color: success)),
          const SizedBox(height: 4),
          Text('The analysis did not identify significant manipulation indicators.',
              style: AppTheme.bodySmall.copyWith(color: textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTimestampsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: widget.analysisResult!.suspiciousFrames.take(10).map((frame) {
          final timestamp = frame['timestamp_fmt'] ?? '${frame['timestamp']}s';
          final score = (frame['score'] * 100).round();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cardBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: highRisk),
                ),
                const SizedBox(width: 12),
                Text(timestamp, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Score: $score%', style: AppTheme.bodyMedium.copyWith(color: highRisk)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConclusion(BuildContext context, AnalysisResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    String conclusion;
    if (result.isHighRisk) {
      conclusion = 'The analyzed media exhibits multiple signals associated with digital manipulation. A risk score of ${result.riskScore}/100 was assigned based on AI analysis of ${result.facesDetected} detected face(s). Human verification is strongly recommended.';
    } else if (result.isMediumRisk) {
      conclusion = 'The analysis identified some indicators that may suggest manipulation. A risk score of ${result.riskScore}/100 was assigned. Further investigation and manual review are recommended.';
    } else if (result.facesDetected == 0) {
      conclusion = result.message.isNotEmpty
          ? result.message
          : 'Unable to perform manipulation analysis. No suitable faces were detected in the media.';
    } else {
      conclusion = 'The analysis indicates the media is likely authentic, with a risk score of ${result.riskScore}/100 based on ${result.facesDetected} detected face(s). No significant manipulation indicators were found.';
    }

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
            '"$conclusion"',
            style: AppTheme.bodyLarge.copyWith(
                color: textPrimary, fontStyle: FontStyle.italic, height: 1.6),
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
