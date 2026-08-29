import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class FindingCard extends StatefulWidget {
  final Finding finding;

  const FindingCard({super.key, required this.finding});

  @override
  State<FindingCard> createState() => _FindingCardState();
}

class _FindingCardState extends State<FindingCard> {
  bool _isHovered = false;

  Color get _accentColor =>
      widget.finding.isCritical ? AppColors.highRisk : AppColors.primary;

  Color _accent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return widget.finding.isCritical
        ? (isDark ? AppColors.highRisk : AppColorsLight.highRisk)
        : (isDark ? AppColors.primary : AppColorsLight.primary);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColorsLight.card;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final highRiskBg = isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final primaryColor = isDark ? AppColors.primary : AppColorsLight.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isHovered ? surfaceElevated : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? _accentColor.withOpacity(0.4)
                : widget.finding.isCritical
                    ? highRisk.withOpacity(0.2)
                    : cardBorder,
            width: 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: _accentColor.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Number badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.finding.isCritical
                    ? highRiskBg
                    : surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.finding.isCritical
                      ? highRisk.withOpacity(0.2)
                      : cardBorder,
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.finding.number}',
                  style: AppTheme.labelMedium.copyWith(
                    color: widget.finding.isCritical
                        ? highRisk
                        : textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Finding text
            Expanded(
              child: Text(
                widget.finding.description,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            if (widget.finding.isCritical) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: highRiskBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: highRisk.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'CRITICAL',
                  style: AppTheme.labelMedium.copyWith(
                    color: highRisk,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
