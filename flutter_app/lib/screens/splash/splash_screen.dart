import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Forensic scan icon
                _buildScanIcon(),
                const SizedBox(height: 32),

                // App name
                Text(
                  AppConstants.appName,
                  style: AppTheme.monospaceLarge.copyWith(
                    letterSpacing: 8,
                    fontSize: 42,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  AppConstants.appSubtitle.toUpperCase(),
                  style: AppTheme.labelLarge.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 4,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 40),

                // Tagline
                Text(
                  AppConstants.splashTagline,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
          Positioned(
            top: 18,
            child: Container(
              width: 1,
              height: 12,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Container(
              width: 1,
              height: 12,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          Positioned(
            left: 18,
            child: Container(
              width: 12,
              height: 1,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          Positioned(
            right: 18,
            child: Container(
              width: 12,
              height: 1,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
