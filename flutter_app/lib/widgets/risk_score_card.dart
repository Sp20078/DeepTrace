import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class RiskScoreCard extends StatefulWidget {
  final int score;
  final RiskLevel riskLevel;
  final String label;

  const RiskScoreCard({
    super.key,
    required this.score,
    required this.riskLevel,
    required this.label,
  });

  @override
  State<RiskScoreCard> createState() => _RiskScoreCardState();
}

class _RiskScoreCardState extends State<RiskScoreCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _gradientController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _gradientController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color get _riskColor {
    switch (widget.riskLevel) {
      case RiskLevel.high:
        return AppColors.highRisk;
      case RiskLevel.medium:
        return AppColors.mediumRisk;
      case RiskLevel.low:
        return AppColors.lowRisk;
    }
  }

  Color get _riskBgColor {
    switch (widget.riskLevel) {
      case RiskLevel.high:
        return AppColors.highRiskBg;
      case RiskLevel.medium:
        return AppColors.mediumRiskBg;
      case RiskLevel.low:
        return AppColors.lowRiskBg;
    }
  }

  String get _riskLabel {
    switch (widget.riskLevel) {
      case RiskLevel.high:
        return '⚠ HIGH RISK';
      case RiskLevel.medium:
        return '⚡ MEDIUM RISK';
      case RiskLevel.low:
        return '✓ LOW RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColorsLight.card;
    final dividerColor = isDark ? AppColors.divider : AppColorsLight.divider;
    final textTertiary =
        isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final score = widget.score;

    return AnimatedBuilder(
      animation: Listenable.merge([_gradientController, _glowController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            gradientAngle: _gradientController.value * 2 * math.pi,
            riskColor: _riskColor,
            glowIntensity: _glowController.value,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Risk badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: _riskBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _riskColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _riskLabel,
                    style: AppTheme.labelLarge.copyWith(
                      color: _riskColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Circular progress with score inside
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 8,
                          color: dividerColor,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value: _progressController.value * score / 100,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_riskColor),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          final displayScore =
                              (_progressController.value * score).round();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$displayScore',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  color: _riskColor,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '/ 100',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  widget.label,
                  style: AppTheme.bodyMedium.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter that draws a rotating gradient border
class _GradientBorderPainter extends CustomPainter {
  final double gradientAngle;
  final Color riskColor;
  final double glowIntensity;

  _GradientBorderPainter({
    required this.gradientAngle,
    required this.riskColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    // Animated gradient that rotates around the border
    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: gradientAngle,
        endAngle: gradientAngle + math.pi * 2,
        colors: [
          riskColor.withOpacity(0.15 + glowIntensity * 0.15),
          riskColor.withOpacity(0.6 + glowIntensity * 0.2),
          riskColor.withOpacity(0.15 + glowIntensity * 0.15),
          riskColor.withOpacity(0.4 + glowIntensity * 0.15),
          riskColor.withOpacity(0.15 + glowIntensity * 0.15),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);

    // Outer glow shadow
    final glowPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: gradientAngle,
        endAngle: gradientAngle + math.pi * 2,
        colors: [
          riskColor.withOpacity(0.0),
          riskColor.withOpacity(0.08 + glowIntensity * 0.06),
          riskColor.withOpacity(0.0),
          riskColor.withOpacity(0.05 + glowIntensity * 0.04),
          riskColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.gradientAngle != gradientAngle ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}
