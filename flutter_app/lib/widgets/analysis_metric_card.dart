import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class AnalysisMetricCard extends StatefulWidget {
  final AnalysisMetric metric;

  const AnalysisMetricCard({super.key, required this.metric});

  @override
  State<AnalysisMetricCard> createState() => _AnalysisMetricCardState();
}

class _AnalysisMetricCardState extends State<AnalysisMetricCard>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fillController.forward();
    });
  }

  @override
  void dispose() {
    _fillController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  Color get _barColor {
    if (widget.metric.score >= 70) return AppColors.highRisk;
    if (widget.metric.score >= 40) return AppColors.mediumRisk;
    return AppColors.lowRisk;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColorsLight.card;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final dividerColor = isDark ? AppColors.divider : AppColorsLight.divider;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isHovered ? surfaceElevated : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? _barColor.withOpacity(0.35)
                : cardBorder,
            width: 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: _barColor.withOpacity(0.1),
                blurRadius: 16,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _barColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _barColor.withOpacity(0.15),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.metric.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.metric.name,
                    style: AppTheme.subtitleMedium,
                  ),
                ),
                AnimatedBuilder(
                  animation: _fillController,
                  builder: (context, child) {
                    final displayScore =
                        (_fillController.value * widget.metric.score).round();
                    return Text(
                      '$displayScore%',
                      style: AppTheme.headingSmall.copyWith(
                        color: _barColor,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AnimatedBuilder(
                animation: _fillController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _fillController.value * widget.metric.score / 100,
                    backgroundColor: dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                    minHeight: 6,
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              widget.metric.description,
              style: AppTheme.bodySmall.copyWith(
                color: textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
