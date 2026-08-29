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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
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

                  // Media preview
                  _buildMediaPreview(context),
                  const SizedBox(height: 20),

                  // Detection callout
                  _buildDetectionCallout(),
                  const SizedBox(height: 24),

                  // Two-column layout on wide screens
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: InvestigationTimeline(
                            timestamps:
                                investigation.suspiciousTimestamps,
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
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Grid background
            CustomPaint(
              size: Size.infinite,
              painter: _EvidenceGridPainter(),
            ),

            // Video placeholder
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card,
                      border: Border.all(
                        color: AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 36,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'suspect_video.mp4',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
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
                  border: Border.all(
                    color: AppColors.highRisk.withOpacity(0.6),
                    width: 2,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.highRisk.withOpacity(0.25),
                      AppColors.highRisk.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Annotation
            Positioned(
              top: 30,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.highRisk.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.highRisk.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'FLAGGED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Corner brackets
            Positioned(
                top: 10,
                left: 10,
                child: _cornerBracket()),
            Positioned(
                top: 10,
                right: 10,
                child: _cornerBracket(mirror: true)),
            Positioned(
                bottom: 10,
                left: 10,
                child: _cornerBracket(flip: true)),
            Positioned(
                bottom: 10,
                right: 10,
                child: _cornerBracket(mirror: true, flip: true)),
          ],
        ),
      ),
    );
  }

  Widget _cornerBracket({bool mirror = false, bool flip = false}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: !flip
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
          bottom: flip
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
          left: !mirror
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
          right: mirror
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDetectionCallout() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.highRiskBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.highRisk.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.highRisk.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.highRisk,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suspicious Region Detected',
                  style: AppTheme.subtitleMedium.copyWith(
                    color: AppColors.highRisk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Potential manipulation artifacts identified around facial boundaries.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text('Frame Analysis', style: AppTheme.subtitleMedium),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tap suspicious frames to inspect',
          style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
        ),
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
                      color: frame.isSuspicious
                          ? AppColors.highRiskBg
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: frame.isSuspicious
                            ? AppColors.highRisk
                            : AppColors.cardBorder,
                        width: frame.isSuspicious ? 2 : 1,
                      ),
                      boxShadow: frame.isSuspicious
                          ? [
                              BoxShadow(
                                color: AppColors.highRisk
                                    .withOpacity(0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          frame.isSuspicious
                              ? Icons.warning_amber_rounded
                              : Icons.image_rounded,
                          color: frame.isSuspicious
                              ? AppColors.highRisk
                              : AppColors.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    frame.timestamp,
                    style: AppTheme.bodySmall.copyWith(
                      color: frame.isSuspicious
                          ? AppColors.highRisk
                          : AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: frame.isSuspicious
                          ? FontWeight.w700
                          : FontWeight.w400,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
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
