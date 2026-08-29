import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Animates a number counting up from 0 to [target]
class AnimatedCounter extends StatefulWidget {
  final int target;
  final TextStyle? style;
  final Duration duration;
  final String suffix;
  final String prefix;

  const AnimatedCounter({
    super.key,
    required this.target,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
    this.suffix = '',
    this.prefix = '',
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0, end: widget.target.toDouble()).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _animation.addListener(() {
      setState(() {
        _displayValue = _animation.value.round();
      });
    });

    // Start after a small delay for staggered effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$widget.prefix$_displayValue${widget.suffix}',
      style: widget.style ?? AppTheme.monospaceLarge,
    );
  }
}

/// A pulsing dot indicator
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = AppColors.primary,
    this.size = 8,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 + _controller.value * 0.4),
                blurRadius: 4 + _controller.value * 6,
                spreadRadius: _controller.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
