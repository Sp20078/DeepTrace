import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../services/api_service.dart';
import '../../widgets/staggered_entry.dart';

class EvidenceScreen extends StatelessWidget {
  final AnalysisResult? analysisResult;

  const EvidenceScreen({super.key, this.analysisResult});

  @override
  Widget build(BuildContext context) {
    if (analysisResult == null) {
      return Scaffold(body: Center(child: Text('No evidence data')));
    }
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final card = isDark ? AppColors.card : AppColorsLight.card;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Evidence Analysis'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: StaggeredEntry(
                staggerDelay: const Duration(milliseconds: 80),
                children: [
                  const SizedBox(height: 16),

                  // Detection callout
                  if (analysisResult!.suspiciousFrames.isNotEmpty)
                    _buildDetectionCallout(context),

                  if (analysisResult!.suspiciousFrames.isNotEmpty)
                    const SizedBox(height: 24),

                  // Suspicious segments
                  if (analysisResult!.suspiciousSegments.isNotEmpty) ...[
                    Text('Suspicious Segments', style: AppTheme.headingSmall),
                    const SizedBox(height: 12),
                    ...analysisResult!.suspiciousSegments.map(
                      (seg) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildSegmentCard(context, seg),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Suspicious frames
                  if (analysisResult!.suspiciousFrames.isNotEmpty) ...[
                    Text('Flagged Frames', style: AppTheme.headingSmall),
                    const SizedBox(height: 6),
                    Text('Frames with highest manipulation scores',
                        style: AppTheme.bodySmall.copyWith(color: textMuted)),
                    const SizedBox(height: 16),
                    _buildFrameThumbnails(context),
                    const SizedBox(height: 24),
                  ],

                  // No evidence
                  if (analysisResult!.suspiciousFrames.isEmpty)
                    _buildNoEvidenceCard(context),

                  // Frame-level results (for video)
                  if (analysisResult!.mediaCategory == 'video' &&
                      analysisResult!.frameResults.isNotEmpty) ...[
                    Text('Frame-Level Results', style: AppTheme.headingSmall),
                    const SizedBox(height: 12),
                    _buildFrameResultsList(context),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionCallout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highRiskBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highRisk.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: highRisk.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_outline_rounded, color: highRisk, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suspicious Frames Detected',
                    style: AppTheme.subtitleMedium.copyWith(color: highRisk)),
                const SizedBox(height: 6),
                Text(
                  '${analysisResult!.suspiciousFrames.length} frame(s) flagged with elevated manipulation scores.',
                  style: AppTheme.bodyMedium.copyWith(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(BuildContext context, dynamic segment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final startFmt = segment['start_fmt'] ?? '${segment['start']}s';
    final endFmt = segment['end_fmt'] ?? '${segment['end']}s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highRisk.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 40,
            decoration: BoxDecoration(
              color: highRisk,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suspicious Segment',
                  style: AppTheme.subtitleMedium.copyWith(color: highRisk)),
              const SizedBox(height: 4),
              Text('$startFmt - $endFmt',
                  style: AppTheme.bodyLarge.copyWith(
                      color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrameThumbnails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;

    final frames = analysisResult!.suspiciousFrames;

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: frames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final frame = frames[index];
          final score = (frame['score'] * 100).round();
          final timestamp = frame['timestamp_fmt'] ?? '${frame['timestamp']}s';

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80, height: 68,
                decoration: BoxDecoration(
                  color: highRiskBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: highRisk, width: 2),
                  boxShadow: [
                    BoxShadow(color: highRisk.withOpacity(0.25), blurRadius: 10, spreadRadius: 1)
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: highRisk, size: 22),
                    const SizedBox(height: 2),
                    Text('$score%', style: TextStyle(
                        color: highRisk, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(timestamp, style: AppTheme.bodySmall.copyWith(
                  color: highRisk, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoEvidenceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: success, size: 48),
          const SizedBox(height: 16),
          Text('No Suspicious Evidence Found',
              style: AppTheme.subtitleMedium.copyWith(color: success)),
          const SizedBox(height: 8),
          Text(
            'No frames were flagged with elevated manipulation scores.',
            style: AppTheme.bodyMedium.copyWith(color: textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFrameResultsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final lowRisk = isDark ? AppColors.lowRisk : AppColorsLight.lowRisk;

    // Show only frames with faces
    final framesWithFaces = analysisResult!.frameResults
        .where((f) => f['faces_found'] > 0)
        .toList();

    if (framesWithFaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: framesWithFaces.take(20).map((frame) {
          final score = (frame['manipulation_score'] * 100).round();
          final timestamp = frame['timestamp_fmt'] ?? '';
          final isSuspicious = frame['manipulation_score'] >= 0.6;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cardBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isSuspicious
                        ? highRisk.withOpacity(0.15)
                        : lowRisk.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSuspicious ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    color: isSuspicious ? highRisk : lowRisk,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timestamp, style: AppTheme.bodyMedium.copyWith(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('${frame['faces_found']} face(s) detected',
                          style: AppTheme.bodySmall.copyWith(color: textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Text('$score%',
                    style: AppTheme.bodyLarge.copyWith(
                        color: isSuspicious ? highRisk : textTertiary,
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
