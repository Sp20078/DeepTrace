import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = true;
  bool _isNavigating = false;
  double _pageProgress = 0.0;
  Timer? _progressTickTimer;

  static const _pageHoldDuration = Duration(seconds: 4);

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Upload',
      subtitle: 'Suspicious Media',
      description:
          'Upload images or videos you want to investigate. Simply drag and drop or select from your device.',
      icon: Icons.cloud_upload_rounded,
      color: Color(0xFF3B82F6),
    ),
    _OnboardingPage(
      title: 'AI-Powered',
      subtitle: 'Forensic Analysis',
      description:
          'Our AI analyzes facial artifacts, temporal inconsistencies, metadata, and other forensic signals.',
      icon: Icons.analytics_rounded,
      color: Color(0xFF8B5CF6),
    ),
    _OnboardingPage(
      title: 'Investigate',
      subtitle: 'The Evidence',
      description:
          'Review detailed risk scores, suspicious regions, and a full forensic report with key findings.',
      icon: Icons.search_rounded,
      color: Color(0xFF22C55E),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startPageTimer();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _progressTickTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Start the 4-second timer + progress bar for the current page.
  void _startPageTimer() {
    _autoScrollTimer?.cancel();
    _progressTickTimer?.cancel();

    _pageProgress = 0.0;
    _isAutoScrolling = true;

    // Tick progress bar every 50ms
    const tickInterval = Duration(milliseconds: 50);
    final totalTicks = _pageHoldDuration.inMilliseconds ~/ tickInterval.inMilliseconds;
    int currentTick = 0;

    _progressTickTimer = Timer.periodic(tickInterval, (timer) {
      if (!mounted || !_isAutoScrolling) {
        timer.cancel();
        return;
      }
      currentTick++;
      setState(() {
        _pageProgress = (currentTick / totalTicks).clamp(0.0, 1.0);
      });
    });

    // After hold duration, advance or complete
    _autoScrollTimer = Timer(_pageHoldDuration, () {
      if (!mounted || _isNavigating) return;
      _progressTickTimer?.cancel();
      setState(() => _pageProgress = 1.0);

      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _completeOnboarding();
      }
    });
  }

  void _onPageChanged(int page) {
    _currentPage = page;
    // Only restart timer if we're in auto-scroll mode
    if (_isAutoScrolling && !_isNavigating) {
      _startPageTimer();
    }
  }

  void _onUserInteract() {
    // Stop auto-scroll when user manually interacts
    _isAutoScrolling = false;
    _autoScrollTimer?.cancel();
    _progressTickTimer?.cancel();
  }

  void _nextPage() {
    _onUserInteract();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _closeOnboarding() {
    _onUserInteract();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    if (_isNavigating) return;
    _isNavigating = true;
    _autoScrollTimer?.cancel();
    _progressTickTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final surface =
        isDark ? AppColors.surface : AppColorsLight.surfaceElevated;

    final accentColor = _pages[_currentPage].color;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Close + progress + counter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _closeOnboarding,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: textMuted),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _isAutoScrolling ? _pageProgress : 0,
                        backgroundColor: textMuted.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentPage + 1}/${_pages.length}',
                    style: AppTheme.labelMedium.copyWith(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                // Stop auto-scroll on manual swipe
                physics: _isAutoScrolling
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index], isDark),
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[index].color
                              : textMuted.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: AppTheme.subtitleMedium.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(0.08),
              border: Border.all(color: page.color.withOpacity(0.15), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: page.color.withOpacity(0.12), width: 1.5),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: page.color.withOpacity(0.18), width: 1.5),
                  ),
                ),
                Icon(page.icon, size: 56, color: page.color.withOpacity(0.8)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: AppTheme.monospaceLarge.copyWith(
              fontSize: 36,
              letterSpacing: -1,
              color: page.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(page.subtitle, style: AppTheme.headingMedium.copyWith(color: textPrimary)),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: AppTheme.bodyLarge.copyWith(color: textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
