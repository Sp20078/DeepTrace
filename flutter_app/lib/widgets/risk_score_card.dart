import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';
import 'animated_counter.dart';

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
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
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
    final score = widget.score;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _riskColor.withOpacity(
                0.2 + _glowController.value * 0.15,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _riskColor.withOpacity(
                  0.06 + _glowController.value * 0.06,
                ),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
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
                    // Background circle
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        color: AppColors.divider,
                      ),
                    ),
                    // Animated progress
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
                    // Score number
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
                                color: AppColors.textTertiary,
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

              // Label
              Text(
                widget.label,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
