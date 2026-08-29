import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isSmall;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isSmall = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryDark = isDark ? AppColors.primaryDark : AppColorsLight.primaryDark;
    final primaryLight = isDark ? AppColors.primaryLight : AppColorsLight.primaryLight;
    final bgColor = widget.isOutlined ? Colors.transparent : primary;
    final fgColor = widget.isOutlined ? primary : Colors.white;
    final borderColor = widget.isOutlined ? primary : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          _pressController.forward();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          _pressController.reverse();
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () {
          _pressController.reverse();
          setState(() => _isPressed = false);
        },
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: widget.isSmall ? 40 : 52,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isSmall ? 16 : 24,
            ),
            decoration: BoxDecoration(
              color: _isHovered && !widget.isOutlined ? primaryDark : bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? primaryLight : borderColor,
                width: widget.isOutlined ? 1.5 : 0,
              ),
              boxShadow: [
                if (_isHovered && !widget.isOutlined)
                  BoxShadow(
                    color: primary.withOpacity(0.35),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                if (_isPressed && !widget.isOutlined)
                  BoxShadow(
                    color: primary.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: widget.isSmall ? 16 : 20,
                    color: fgColor,
                  ),
                  SizedBox(width: widget.isSmall ? 6 : 8),
                ],
                Text(
                  widget.label,
                  style:
                      (widget.isSmall ? AppTheme.labelLarge : AppTheme.subtitleMedium)
                          .copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
