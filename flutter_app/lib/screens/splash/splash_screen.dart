import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _ringController;
  late AnimationController _scanController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _mainController.forward();

    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _ringController.dispose();
    _scanController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background grid
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(
              color: AppColors.primary.withOpacity(0.04),
            ),
          ),

          // Main centered content
          Center(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _mainController,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _mainController,
                    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAnimatedIcon(),
                    const SizedBox(height: 36),

                    // Hero-wrapped logo text
                    Hero(
                      tag: 'deeptrace-logo',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          AppConstants.appName,
                          style: AppTheme.monospaceLarge.copyWith(
                            letterSpacing: 8,
                            fontSize: 44,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildStaggeredText(
                      AppConstants.appSubtitle.toUpperCase(),
                      AppTheme.labelLarge.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 4,
                        fontSize: 12,
                      ),
                      delay: 0.5,
                    ),

                    const SizedBox(height: 44),

                    _buildStaggeredText(
                      AppConstants.splashTagline,
                      AppTheme.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                      delay: 0.7,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredText(String text, TextStyle style, {double delay = 0}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _mainController,
        curve: Interval(delay, (delay + 0.4).clamp(0, 1), curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(delay, (delay + 0.5).clamp(0, 1), curve: Curves.easeOutCubic),
          ),
        ),
        child: Text(text, style: style),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _ringController.value * 2 * math.pi,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _ArcPainter(
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 72 + _glowController.value * 6,
                height: 72 + _glowController.value * 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15 + _glowController.value * 0.15),
                    width: 1,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4 + _glowController.value * 0.4),
                      blurRadius: 8 + _glowController.value * 8,
                      spreadRadius: _glowController.value * 3,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 16,
            child: Container(width: 1, height: 14, color: AppColors.primary.withOpacity(0.5)),
          ),
          Positioned(
            bottom: 16,
            child: Container(width: 1, height: 14, color: AppColors.primary.withOpacity(0.5)),
          ),
          Positioned(
            left: 16,
            child: Container(width: 14, height: 1, color: AppColors.primary.withOpacity(0.5)),
          ),
          Positioned(
            right: 16,
            child: Container(width: 14, height: 1, color: AppColors.primary.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    canvas.drawArc(rect, -math.pi / 4, math.pi / 2, false, paint);
    canvas.drawArc(rect, math.pi * 3 / 4, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => false;
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}
