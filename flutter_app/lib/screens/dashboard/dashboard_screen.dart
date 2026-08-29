import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../models/investigation.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/staggered_entry.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroPulseController;
  bool _showContent = false;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _heroPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _heroPulseController.dispose();
    super.dispose();
  }

  // Theme-aware color helpers
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? AppColors.background : AppColorsLight.background;
  Color get _surface => _isDark ? AppColors.surface : AppColorsLight.surface;
  Color get _surfaceElevated =>
      _isDark ? AppColors.surfaceElevated : AppColorsLight.surfaceElevated;
  Color get _card => _isDark ? AppColors.card : AppColorsLight.card;
  Color get _cardBorder =>
      _isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
  Color get _primary => _isDark ? AppColors.primary : AppColorsLight.primary;
  Color get _primaryGlow =>
      _isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
  Color get _textPrimary =>
      _isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  Color get _textSecondary =>
      _isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color get _textTertiary =>
      _isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
  Color get _textMuted =>
      _isDark ? AppColors.textMuted : AppColorsLight.textMuted;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  setState(() => _scrollOffset = notification.metrics.pixels);
                }
                return false;
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 40),

                    // Parallax hero section
                    _buildParallaxHero(isWide),
                    const SizedBox(height: 40),
                    _buildHowItWorks(context),
                    const SizedBox(height: 40),
                    _buildRecentInvestigations(context),
                    const SizedBox(height: 40),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Text(
                          AppConstants.disclaimer,
                          style: AppTheme.bodySmall.copyWith(
                            color: _textMuted,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParallaxHero(bool isWide) {
    // Parallax: hero shrinks and fades as you scroll
    final parallaxFactor = (_scrollOffset / 400).clamp(0.0, 1.0);
    final heroScale = 1.0 - parallaxFactor * 0.05;
    final heroOpacity = 1.0 - parallaxFactor * 0.4;

    return AnimatedBuilder(
      animation: _heroPulseController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..scale(heroScale)
            ..translate(0.0, -parallaxFactor * 20),
          child: Opacity(
            opacity: heroOpacity,
            child: GlowCard(
              glowColor: _primary.withOpacity(0.15),
              borderColor: _primary.withOpacity(0.15),
              borderRadius: 18,
              padding: EdgeInsets.all(isWide ? 36 : 28),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildHeroContent(context)),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildHeroVisual()),
                      ],
                    )
                  : _buildHeroContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _heroPulseController,
          builder: (context, child) {
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary,
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(
                      0.3 + _heroPulseController.value * 0.3,
                    ),
                    blurRadius: 8 + _heroPulseController.value * 4,
                    spreadRadius: 2 + _heroPulseController.value * 2,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: AppTheme.monospace.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppConstants.appSubtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: _textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Investigate suspicious media', style: AppTheme.headingMedium),
        const SizedBox(height: 12),
        Text(
          'Upload an image or video and analyze its authenticity using AI-powered forensic signals.',
          style: AppTheme.bodyLarge.copyWith(
            color: _textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Upload Evidence',
          icon: Icons.add_rounded,
          onPressed: () => Navigator.of(context).pushNamed('/upload'),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Try Demo Investigation',
          icon: Icons.science_rounded,
          isOutlined: true,
          onPressed: () =>
              Navigator.of(context).pushNamed('/analysis', arguments: true),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text('Supported: ',
                style: AppTheme.bodySmall.copyWith(color: _textMuted)),
            _formatChip(Icons.image_rounded, 'Images'),
            const SizedBox(width: 8),
            _formatChip(Icons.videocam_rounded, 'Videos'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return AnimatedBuilder(
      animation: _heroPulseController,
      builder: (context, child) {
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _primary.withOpacity(
                0.08 + _heroPulseController.value * 0.08,
              ),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _circle(100, 0.12),
              _circle(70, 0.18),
              _circle(40, 0.25),
              Icon(Icons.shield_rounded,
                  size: 28, color: _primary.withOpacity(0.5)),
              Positioned(top: 12, left: 12, child: _cornerBracket()),
              Positioned(
                  top: 12, right: 12, child: _cornerBracket(mirror: true)),
              Positioned(
                  bottom: 12, left: 12, child: _cornerBracket(flip: true)),
              Positioned(
                  bottom: 12,
                  right: 12,
                  child: _cornerBracket(mirror: true, flip: true)),
            ],
          ),
        );
      },
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _primary.withOpacity(opacity)),
      ),
    );
  }

  Widget _cornerBracket({bool mirror = false, bool flip = false}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top:
              !flip ? BorderSide(color: _primary, width: 1.5) : BorderSide.none,
          bottom:
              flip ? BorderSide(color: _primary, width: 1.5) : BorderSide.none,
          left: !mirror
              ? BorderSide(color: _primary, width: 1.5)
              : BorderSide.none,
          right: mirror
              ? BorderSide(color: _primary, width: 1.5)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _formatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textTertiary),
          const SizedBox(width: 5),
          Text(label,
              style: AppTheme.bodySmall
                  .copyWith(color: _textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    final steps = [
      ('Upload', Icons.cloud_upload_rounded),
      ('Analyze', Icons.analytics_rounded),
      ('Investigate', Icons.search_rounded),
      ('Report', Icons.description_rounded),
    ];
    final isWide = ResponsiveWrapper.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How it works', style: AppTheme.headingSmall),
        const SizedBox(height: 20),
        StaggeredEntry(
          staggerDelay: const Duration(milliseconds: 100),
          children: [
            isWide
                ? Row(
                    children: [
                      for (int i = 0; i < steps.length; i++) ...[
                        Expanded(child: _buildStepItem(steps[i], i + 1)),
                        if (i < steps.length - 1)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: _textMuted.withOpacity(0.5)),
                          ),
                      ],
                    ],
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: steps
                        .map((s) => SizedBox(
                              width: (MediaQuery.sizeOf(context).width -
                                      ResponsiveWrapper.padding(context) * 2 -
                                      36) /
                                  4,
                              child: _buildStepItem(s, steps.indexOf(s) + 1),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem((String, IconData) step, int number) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryGlow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(step.$2, color: _primary, size: 22),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              step.$1,
              style: AppTheme.bodySmall.copyWith(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvestigations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Investigations', style: AppTheme.headingSmall),
        const SizedBox(height: 18),
        ...MockData.recentInvestigations.map(
          (inv) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EvidenceCard(
              investigation: inv,
              onTap: () => Navigator.of(context).pushNamed('/results'),
            ),
          ),
        ),
      ],
    );
  }
}
