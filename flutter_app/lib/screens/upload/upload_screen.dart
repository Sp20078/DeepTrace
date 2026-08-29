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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
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

                  // Description
                  Text(
                    'Select digital media you want to investigate.',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Media type options
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

                  // Upload area
                  _buildDropArea(context),
                  const SizedBox(height: 28),

                  // Supported formats
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Supported formats',
                          style: AppTheme.labelMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'JPG, PNG, MP4, MOV',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Demo option
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
    Navigator.of(context)
        .pushReplacementNamed('/analysis', arguments: true);
  }

  Widget _buildDropArea(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDemo(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.15),
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
                  color: AppColors.primaryGlow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: 32,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Drag & drop or tap to select',
                style: AppTheme.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Image or video file',
                style: AppTheme.bodySmall,
              ),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
