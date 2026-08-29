import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/investigation.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/evidence_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              _buildHeader(),
              const SizedBox(height: 40),

              // Hero section
              _buildHeroSection(context),
              const SizedBox(height: 40),

              // How it works
              _buildHowItWorks(),
              const SizedBox(height: 40),

              // Recent Investigations
              _buildRecentInvestigations(context),
              const SizedBox(height: 40),

              // Disclaimer footer
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
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App name with accent
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: AppTheme.monospace.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            AppConstants.appSubtitle,
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
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
          const SizedBox(height: 24),

          // Primary CTA
          PrimaryButton(
            label: 'Upload Evidence',
            icon: Icons.add_rounded,
            onPressed: () {
              Navigator.of(context).pushNamed('/upload');
            },
          ),

          const SizedBox(height: 16),

          // Demo button
          PrimaryButton(
            label: 'Try Demo Investigation',
            icon: Icons.science_rounded,
            isOutlined: true,
            onPressed: () {
              Navigator.of(context).pushNamed('/analysis', arguments: true);
            },
          ),

          const SizedBox(height: 20),

          // Supported formats
          Row(
            children: [
              Text(
                'Supported: ',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              _formatChip(Icons.image_rounded, 'Images'),
              const SizedBox(width: 8),
              _formatChip(Icons.videocam_rounded, 'Videos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildHowItWorks() {
    final steps = [
      ('1', 'Upload', Icons.cloud_upload_rounded),
      ('2', 'Analyze', Icons.analytics_rounded),
      ('3', 'Investigate', Icons.search_rounded),
      ('4', 'Report', Icons.description_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How it works', style: AppTheme.headingSmall),
        const SizedBox(height: 18),
        Row(
          children: steps.map((step) {
            final isLast = step == steps.last;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            step.$3,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.$2,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
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
