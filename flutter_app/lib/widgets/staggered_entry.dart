import 'package:flutter/material.dart';

/// Wraps a list of children with staggered fade-in + slide-up animations
class StaggeredEntry extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animDuration;
  final double slideDistance;

  const StaggeredEntry({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.animDuration = const Duration(milliseconds: 450),
    this.slideDistance = 20,
  });

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.children.length, (i) {
      return AnimationController(
        vsync: this,
        duration: widget.animDuration,
      );
    });

    _fadeAnims = _controllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    _slideAnims = _controllers.map((c) {
      return Tween<Offset>(
        begin: Offset(0, widget.slideDistance / 100),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
      );
    }).toList();

    _startStaggered();
  }

  void _startStaggered() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(widget.staggerDelay);
      if (mounted) _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnims[i],
              child: SlideTransition(
                position: _slideAnims[i],
                child: child,
              ),
            );
          },
          child: widget.children[i],
        );
      }),
    );
  }
}
