import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class InvestigationTimeline extends StatefulWidget {
  final List<SuspiciousTimestamp> timestamps;

  const InvestigationTimeline({super.key, required this.timestamps});

  @override
  State<InvestigationTimeline> createState() => _InvestigationTimelineState();
}

class _InvestigationTimelineState extends State<InvestigationTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final dividerColor = isDark ? AppColors.divider : AppColorsLight.divider;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Timeline', style: AppTheme.subtitleMedium),
                ],
              ),
              const SizedBox(height: 24),

              // Timeline bar
              SizedBox(
                height: 100,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Track line
                        Positioned(
                          top: 20,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Gradient fill
                        Positioned(
                          top: 20,
                          left: 0,
                          width: constraints.maxWidth * 0.63,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary,
                                  highRisk,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      highRisk.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Timestamp markers
                        for (int i = 0; i < widget.timestamps.length; i++)
                          Positioned(
                            left: _getPosition(
                              i,
                              constraints.maxWidth,
                            ),
                            top: 0,
                            child: _buildMarker(
                              widget.timestamps[i],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarker(SuspiciousTimestamp ts) {
    final isAnomaly = ts.isHighAnomaly;
    final anomalyPulse = _pulseController.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highRiskColor = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final highRiskBgColor = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final textTertiaryColor = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        // Time label
        Text(
          ts.time,
          style: AppTheme.bodySmall.copyWith(
            color: isAnomaly ? highRiskColor : textTertiaryColor,
            fontSize: 11,
            fontWeight:
                isAnomaly ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),

        // Dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isAnomaly ? 16 : 8,
          height: isAnomaly ? 16 : 8,
          decoration: BoxDecoration(
            color: isAnomaly ? highRiskColor : textTertiaryColor,
            shape: BoxShape.circle,
            boxShadow: isAnomaly
                ? [
                    BoxShadow(
                      color: highRiskColor.withOpacity(
                        0.3 + anomalyPulse * 0.3,
                      ),
                      blurRadius: 8 + anomalyPulse * 6,
                      spreadRadius: anomalyPulse * 3,
                    ),
                  ]
                : [],
          ),
        ),

        // Label
        if (ts.label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: isAnomaly
                ? BoxDecoration(
                    color: highRiskBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: highRiskColor.withOpacity(0.2),
                    ),
                  )
                : null,
            child: Text(
              ts.label,
              style: AppTheme.bodySmall.copyWith(
                color: isAnomaly
                    ? highRiskColor
                    : textMutedColor,
                fontSize: 10,
                fontWeight: isAnomaly
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  double _getPosition(int index, double totalWidth) {
    if (widget.timestamps.length <= 1) return 0;
    final fraction = index / (widget.timestamps.length - 1);
    final position = fraction * totalWidth - 14;
    return position.clamp(0.0, totalWidth - 28);
  }
}
