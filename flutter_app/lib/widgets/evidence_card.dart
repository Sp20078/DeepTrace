import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../models/investigation.dart';

class EvidenceCard extends StatefulWidget {
  final RecentInvestigation investigation;
  final VoidCallback? onTap;

  const EvidenceCard({
    super.key,
    required this.investigation,
    this.onTap,
  });

  @override
  State<EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<EvidenceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color get _riskColor {
    switch (widget.investigation.riskLevel) {
      case RiskLevel.high:
        return AppColors.highRisk;
      case RiskLevel.medium:
        return AppColors.mediumRisk;
      case RiskLevel.low:
        return AppColors.lowRisk;
    }
  }

  Color get _riskBgColor {
    switch (widget.investigation.riskLevel) {
      case RiskLevel.high:
        return AppColors.highRiskBg;
      case RiskLevel.medium:
        return AppColors.mediumRiskBg;
      case RiskLevel.low:
        return AppColors.lowRiskBg;
    }
  }

  String get _riskLabel {
    switch (widget.investigation.riskLevel) {
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.low:
        return 'LOW RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColorsLight.card;
    final surfaceElevated = isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered ? surfaceElevated : cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? _riskColor.withOpacity(0.4)
                  : cardBorder,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: _riskColor.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Row(
            children: [
              // Risk accent bar
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _riskColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _riskColor.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // File icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _riskBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _riskColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.investigation.fileName.endsWith('.mp4') ||
                          widget.investigation.fileName.endsWith('.mov')
                      ? Icons.videocam_rounded
                      : Icons.image_rounded,
                  color: _riskColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.investigation.fileName,
                      style: AppTheme.subtitleMedium.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _riskLabel,
                      style: AppTheme.labelMedium.copyWith(
                        color: _riskColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.investigation.riskScore}',
                    style: AppTheme.headingSmall.copyWith(
                      color: _riskColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
