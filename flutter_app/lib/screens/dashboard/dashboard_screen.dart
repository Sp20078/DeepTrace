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

  @override
  void initState() {
    super.initState();
    _heroPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Stagger content appearance
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _heroPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildHeroSection(context, isWide),
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
                          color: AppColors.textMuted,
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
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Animated pulsing dot
        AnimatedBuilder(
          animation: _heroPulseController,
          builder: (context, child) {
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(
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
        Column(
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
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isWide) {
    return GlowCard(
      glowColor: AppColors.primary.withOpacity(0.15),
      borderColor: AppColors.primary.withOpacity(0.15),
      borderRadius: 18,
      padding: EdgeInsets.all(isWide ? 36 : 28),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: text + buttons
                Expanded(
                  flex: 3,
                  child: _buildHeroContent(context),
                ),
                const SizedBox(width: 40),
                // Right: visual element
                Expanded(
                  flex: 2,
                  child: _buildHeroVisual(),
                ),
              ],
            )
          : _buildHeroContent(context),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investigate suspicious media',
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Upload an image or video and analyze its authenticity using AI-powered forensic signals.',
          style: AppTheme.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Upload Evidence',
          icon: Icons.add_rounded,
          onPressed: () {
            Navigator.of(context).pushNamed('/upload');
          },
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Try Demo Investigation',
          icon: Icons.science_rounded,
          isOutlined: true,
          onPressed: () {
            Navigator.of(context).pushNamed('/analysis', arguments: true);
          },
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text(
              'Supported: ',
              style: AppTheme.bodySmall.copyWith(color: AppColors.textMuted),
            ),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(
                0.08 + _heroPulseController.value * 0.08,
              ),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric circles
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                ),
              ),
              // Center icon
              Icon(
                Icons.shield_rounded,
                size: 28,
                color: AppColors.primary.withOpacity(0.5),
              ),
              // Corner brackets
              Positioned(
                top: 12,
                left: 12,
                child: _cornerBracket(),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _cornerBracket(mirror: true),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: _cornerBracket(flip: true),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: _cornerBracket(mirror: true, flip: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cornerBracket({bool mirror = false, bool flip = false}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: !flip
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
          bottom: flip
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
          left: !mirror
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
          right: mirror
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _formatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
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
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(step.$2, color: AppColors.primary, size: 22),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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
                color: AppColors.textSecondary,
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
              onTap: () {
                Navigator.of(context).pushNamed('/results');
              },
            ),
          ),
        ),
      ],
    );
  }
}
