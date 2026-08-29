import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_entry.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final cardColor = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upload Evidence'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: StaggeredEntry(
                staggerDelay: const Duration(milliseconds: 80),
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Select digital media you want to investigate.',
                    style: AppTheme.bodyLarge.copyWith(color: textSecondary),
                  ),
                  const SizedBox(height: 32),
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: _MediaTypeCard(
                                icon: Icons.photo_camera_rounded,
                                label: 'Image',
                                description: 'JPG, PNG',
                                onTap: () => _selectDemo(context),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MediaTypeCard(
                                icon: Icons.videocam_rounded,
                                label: 'Video',
                                description: 'MP4, MOV',
                                onTap: () => _selectDemo(context),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _MediaTypeCard(
                              icon: Icons.photo_camera_rounded,
                              label: 'Image',
                              description: 'JPG, PNG',
                              onTap: () => _selectDemo(context),
                            ),
                            const SizedBox(height: 12),
                            _MediaTypeCard(
                              icon: Icons.videocam_rounded,
                              label: 'Video',
                              description: 'MP4, MOV',
                              onTap: () => _selectDemo(context),
                            ),
                          ],
                        ),
                  const SizedBox(height: 28),
                  _buildDropArea(context),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        Text('Supported formats',
                            style: AppTheme.labelMedium.copyWith(color: textTertiary)),
                        const SizedBox(height: 6),
                        Text('JPG, PNG, MP4, MOV',
                            style: AppTheme.bodySmall.copyWith(color: textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Try Demo Evidence',
                    icon: Icons.science_rounded,
                    isOutlined: true,
                    onPressed: () => _selectDemo(context),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectDemo(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/analysis', arguments: true);
  }

  Widget _buildDropArea(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: () => _selectDemo(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withOpacity(0.15),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primaryGlow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: 32,
                  color: primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text('Drag & drop or tap to select',
                  style: AppTheme.subtitleMedium.copyWith(color: textSecondary)),
              const SizedBox(height: 8),
              Text('Image or video file', style: AppTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _MediaTypeCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryGlow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.subtitleMedium),
                  const SizedBox(height: 4),
                  Text(description, style: AppTheme.bodySmall),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
