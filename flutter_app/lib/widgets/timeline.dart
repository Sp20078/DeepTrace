import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class InvestigationTimeline extends StatelessWidget {
  final List<SuspiciousTimestamp> timestamps;

  const InvestigationTimeline({
    super.key,
    required this.timestamps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: AppTheme.subtitleMedium,
          ),
          const SizedBox(height: 20),

          // Timeline bar
          SizedBox(
            height: 80,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Track line
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Progress fill (up to suspicious point)
                    Positioned(
                      top: 16,
                      left: 0,
                      width: constraints.maxWidth * 0.63,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.highRisk],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Timestamp markers
                    for (int i = 0; i < timestamps.length; i++)
                      Positioned(
                        left: _getPosition(i, constraints.maxWidth),
                        top: 0,
                        child: Column(
                          children: [
                            Text(
                              timestamps[i].time,
                              style: AppTheme.bodySmall.copyWith(
                                color: timestamps[i].isHighAnomaly
                                    ? AppColors.highRisk
                                    : AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: timestamps[i].isHighAnomaly
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: timestamps[i].isHighAnomaly ? 14 : 8,
                              height: timestamps[i].isHighAnomaly ? 14 : 8,
                              decoration: BoxDecoration(
                                color: timestamps[i].isHighAnomaly
                                    ? AppColors.highRisk
                                    : AppColors.textTertiary,
                                shape: BoxShape.circle,
                                boxShadow: timestamps[i].isHighAnomaly
                                    ? [
                                        BoxShadow(
                                          color: AppColors.highRisk
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                            ),
                            if (timestamps[i].label.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: timestamps[i].isHighAnomaly
                                    ? BoxDecoration(
                                        color: AppColors.highRiskBg,
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    : null,
                                child: Text(
                                  timestamps[i].label,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: timestamps[i].isHighAnomaly
                                        ? AppColors.highRisk
                                        : AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: timestamps[i].isHighAnomaly
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
  }

  double _getPosition(int index, double totalWidth) {
    // Distribute timestamps evenly
    if (timestamps.length <= 1) return 0;
    final fraction = index / (timestamps.length - 1);
    final position = fraction * totalWidth - 14;
    return position.clamp(0.0, totalWidth - 28);
  }
}
