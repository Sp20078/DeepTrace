import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/investigation.dart';
import '../../widgets/timeline.dart';

class EvidenceScreen extends StatelessWidget {
  const EvidenceScreen({super.key});

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
        title: const Text('Evidence Analysis'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Media preview with heatmap overlay
              _buildMediaPreview(),
              const SizedBox(height: 20),

              // Detection callout
              _buildDetectionCallout(),
              const SizedBox(height: 24),

              // Timeline
              InvestigationTimeline(
                timestamps: investigation.suspiciousTimestamps,
              ),
              const SizedBox(height: 28),

              // Frame thumbnails
              _buildFrameThumbnails(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Stack(
        children: [
          // Video placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  size: 56,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  'suspect_video.mp4',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Heatmap overlay - suspicious region
          Positioned(
            top: 50,
            right: 60,
            width: 100,
            height: 100,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.highRisk.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '⚠ FLAGGED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          // Corner crosshair decorations
          Positioned(
            top: 8,
            left: 8,
            child: _cornerBracket(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _cornerBracket(flipped: true),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: _cornerBracket(flipped: false, bottom: true),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: _cornerBracket(flipped: true, bottom: true),
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket({bool flipped = false, bool bottom = false}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: !bottom
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
          bottom: bottom
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
          left: !flipped
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
          right: flipped
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDetectionCallout() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.highRiskBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.highRisk.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.highRisk,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Suspicious Region Detected',
                style: AppTheme.subtitleMedium.copyWith(
                  color: AppColors.highRisk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Potential manipulation artifacts identified around facial boundaries.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
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
      _FrameData('00:14', true),   // Suspicious
      _FrameData('00:16', true),   // Suspicious
      _FrameData('00:19', false),
      _FrameData('00:22', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frame Analysis', style: AppTheme.subtitleMedium),
        const SizedBox(height: 4),
        Text(
          'Tap suspicious frames to inspect',
          style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: frames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final frame = frames[index];
              return Column(
                children: [
                  Container(
                    width: 72,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: frame.isSuspicious
                            ? AppColors.highRisk
                            : AppColors.cardBorder,
                        width: frame.isSuspicious ? 2 : 1,
                      ),
                      boxShadow: frame.isSuspicious
                          ? [
                              BoxShadow(
                                color: AppColors.highRisk.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_rounded,
                        color: frame.isSuspicious
                            ? AppColors.highRisk
                            : AppColors.textMuted,
                        size: 22,
                      ),
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
