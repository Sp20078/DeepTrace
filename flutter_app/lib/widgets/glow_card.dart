import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A card with optional glow effect, subtle border, and hover animation
class GlowCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final Color? borderColor;
  final double borderRadius;
  final bool enableHover;
  final VoidCallback? onTap;

  const GlowCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.glowColor,
    this.borderColor,
    this.borderRadius = 14,
    this.enableHover = true,
    this.onTap,
  });

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final defaultBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final defaultCard = isDark ? AppColors.card : AppColorsLight.card;
    final glow = widget.glowColor ?? defaultGlow;
    final border = widget.borderColor ?? defaultBorder;

    return MouseRegion(
      onEnter: widget.enableHover
          ? (_) {
              setState(() => _isHovered = true);
              _controller.forward();
            }
          : null,
      onExit: widget.enableHover
          ? (_) {
              setState(() => _isHovered = false);
              _controller.reverse();
            }
          : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: widget.margin,
            padding: widget.padding ?? const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: defaultCard,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _isHovered
                    ? (widget.borderColor ?? AppColors.primary).withOpacity(0.5)
                    : border,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: glow,
                        blurRadius: 20,
                        spreadRadius: -2,
                      ),
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
