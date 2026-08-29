import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../models/investigation.dart';
import '../../widgets/timeline.dart';
import '../../widgets/staggered_entry.dart';

class EvidenceScreen extends StatelessWidget {
  const EvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final investigation = MockData.demoInvestigation;
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);
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
                  _buildMediaPreview(context),
                  const SizedBox(height: 20),
                  _buildDetectionCallout(context),
                  const SizedBox(height: 24),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: InvestigationTimeline(
                            timestamps: investigation.suspiciousTimestamps,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: _buildFrameThumbnails(context),
                        ),
                      ],
                    )
                  else ...[
                    InvestigationTimeline(
                      timestamps: investigation.suspiciousTimestamps,
                    ),
                    const SizedBox(height: 24),
                    _buildFrameThumbnails(context),
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

  Widget _buildMediaPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;

    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _EvidenceGridPainter(color: primary)),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: card,
                      border: Border.all(color: textMuted.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.play_arrow_rounded, size: 36, color: textTertiary),
                  ),
                  const SizedBox(height: 12),
                  Text('suspect_video.mp4',
                      style: AppTheme.bodySmall.copyWith(color: textTertiary)),
                ],
              ),
            ),

            // Heatmap overlay
            Positioned(
              top: 50,
              right: 80,
              width: 110,
              height: 110,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: highRisk.withOpacity(0.6), width: 2),
                  gradient: RadialGradient(colors: [
                    highRisk.withOpacity(0.25),
                    highRisk.withOpacity(0.05),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            // FLAGGED annotation
            Positioned(
              top: 30,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: highRisk.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: highRisk.withOpacity(0.3), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    const Text('FLAGGED',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ],
                ),
              ),
            ),

            Positioned(top: 10, left: 10, child: _cornerBracket(context)),
            Positioned(top: 10, right: 10, child: _cornerBracket(context, mirror: true)),
            Positioned(bottom: 10, left: 10, child: _cornerBracket(context, flip: true)),
            Positioned(bottom: 10, right: 10, child: _cornerBracket(context, mirror: true, flip: true)),
          ],
        ),
      ),
    );
  }

  Widget _cornerBracket(BuildContext context, {bool mirror = false, bool flip = false}) {
    final primary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.primary
        : AppColorsLight.primary;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: !flip ? BorderSide(color: primary, width: 1.5) : BorderSide.none,
          bottom: flip ? BorderSide(color: primary, width: 1.5) : BorderSide.none,
          left: !mirror ? BorderSide(color: primary, width: 1.5) : BorderSide.none,
          right: mirror ? BorderSide(color: primary, width: 1.5) : BorderSide.none,
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
            width: 36,
            height: 36,
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
                Text('Suspicious Region Detected',
                    style: AppTheme.subtitleMedium.copyWith(color: highRisk)),
                const SizedBox(height: 6),
                Text(
                  'Potential manipulation artifacts identified around facial boundaries.',
                  style: AppTheme.bodyMedium.copyWith(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameThumbnails(BuildContext context) {
    final frames = [
      _FrameData('00:02', false),
      _FrameData('00:05', false),
      _FrameData('00:08', false),
      _FrameData('00:11', false),
      _FrameData('00:14', true),
      _FrameData('00:16', true),
      _FrameData('00:19', false),
      _FrameData('00:22', false),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
            ),
            const SizedBox(width: 10),
            Text('Frame Analysis', style: AppTheme.subtitleMedium),
          ],
        ),
        const SizedBox(height: 6),
        Text('Tap suspicious frames to inspect',
            style: AppTheme.bodySmall.copyWith(color: textMuted)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: frames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final frame = frames[index];
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 68,
                    decoration: BoxDecoration(
                      color: frame.isSuspicious ? highRiskBg : surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: frame.isSuspicious ? highRisk : cardBorder,
                        width: frame.isSuspicious ? 2 : 1,
                      ),
                      boxShadow: frame.isSuspicious
                          ? [BoxShadow(color: highRisk.withOpacity(0.25), blurRadius: 10, spreadRadius: 1)]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          frame.isSuspicious ? Icons.warning_amber_rounded : Icons.image_rounded,
                          color: frame.isSuspicious ? highRisk : textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    frame.timestamp,
                    style: AppTheme.bodySmall.copyWith(
                      color: frame.isSuspicious ? highRisk : textTertiary,
                      fontSize: 10,
                      fontWeight: frame.isSuspicious ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FrameData {
  final String timestamp;
  final bool isSuspicious;
  const _FrameData(this.timestamp, this.isSuspicious);
}

class _EvidenceGridPainter extends CustomPainter {
  final Color color;
  _EvidenceGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
