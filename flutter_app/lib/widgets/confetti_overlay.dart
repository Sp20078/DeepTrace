import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool show;
  final VoidCallback? onComplete;

  const ConfettiOverlay({super.key, required this.show, this.onComplete});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });

    _particles = _generateParticles();

    if (widget.show) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _particles = _generateParticles();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _generateParticles() {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
    ];

    return List.generate(40, (i) {
      return _Particle(
        color: colors[_random.nextInt(colors.length)],
        x: _random.nextDouble(),
        startY: -0.05 - _random.nextDouble() * 0.1,
        speedY: 0.5 + _random.nextDouble() * 1.0,
        speedX: (_random.nextDouble() - 0.5) * 0.4,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        size: 4 + _random.nextDouble() * 6,
        shape: _random.nextBool() ? _Shape.circle : _Shape.rect,
        delay: _random.nextDouble() * 0.2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating && _controller.value == 0) {
      return const SizedBox.shrink();
    }

    // IgnorePointer prevents confetti from blocking taps underneath
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

enum _Shape { circle, rect }

class _Particle {
  final Color color;
  final double x;
  final double startY;
  final double speedY;
  final double speedX;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final _Shape shape;
  final double delay;

  const _Particle({
    required this.color,
    required this.x,
    required this.startY,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.shape,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = size.width * p.x + size.width * p.speedX * t;
      final y =
          size.height * (p.startY + p.speedY * t) + 20 * math.sin(t * 4);
      final opacity = (1.0 - t * 0.8).clamp(0.0, 1.0);
      final gravity = t * t * 0.3;
      final adjustedY = y + size.height * gravity;

      if (adjustedY > size.height + 20) continue;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, adjustedY);
      canvas.rotate(p.rotation + p.rotationSpeed * t);

      if (p.shape == _Shape.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
