import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_entry.dart';
import '../../services/api_service.dart';
import '../results/results_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int _selectedFileSize = 0;
  bool _isAnalyzing = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'tiff',
                            'mp4', 'mov', 'avi', 'webm', 'mkv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        // On web: file.bytes is available, file.path throws
        // On mobile: file.bytes may be null but file.path works
        // Solution: always use bytes — file_picker provides them on web,
        // and on mobile we can read them via http.MultipartFile
        final bytes = file.bytes;
        if (bytes != null) {
          setState(() {
            _selectedFileBytes = bytes;
            _selectedFileName = file.name;
            _selectedFileSize = file.size;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = 'Could not read file bytes. Try a different file.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _startAnalysis() async {
    if (_selectedFileBytes == null) {
      setState(() {
        _errorMessage = 'Please select a file first.';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.analyzeFile(
        _selectedFileBytes!,
        fileName: _selectedFileName,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(analysisResult: result),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Connection error. Is the backend server running?\n$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final primary = isDark ? AppColors.primary : AppColorsLight.primary;
    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final highRisk = isDark ? AppColors.highRisk : AppColorsLight.highRisk;

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

                  // File type cards
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: _MediaTypeCard(
                                icon: Icons.photo_camera_rounded,
                                label: 'Image',
                                description: 'JPG, PNG, WebP',
                                onTap: _pickFile,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MediaTypeCard(
                                icon: Icons.videocam_rounded,
                                label: 'Video',
                                description: 'MP4, MOV, AVI',
                                onTap: _pickFile,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _MediaTypeCard(
                              icon: Icons.photo_camera_rounded,
                              label: 'Image',
                              description: 'JPG, PNG, WebP',
                              onTap: _pickFile,
                            ),
                            const SizedBox(height: 12),
                            _MediaTypeCard(
                              icon: Icons.videocam_rounded,
                              label: 'Video',
                              description: 'MP4, MOV, AVI',
                              onTap: _pickFile,
                            ),
                          ],
                        ),
                  const SizedBox(height: 28),

                  // Drop area / selected file display
                  _buildDropArea(context, surface, primary, primaryGlow, textSecondary),
                  const SizedBox(height: 28),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: highRisk.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: highRisk.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: highRisk, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTheme.bodyMedium.copyWith(
                                color: highRisk,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null) const SizedBox(height: 20),

                  // Supported formats
                  Center(
                    child: Column(
                      children: [
                        Text('Supported formats',
                            style: AppTheme.labelMedium.copyWith(color: textTertiary)),
                        const SizedBox(height: 6),
                        Text('JPG, PNG, WebP, BMP, TIFF, MP4, MOV, AVI, WebM, MKV',
                            style: AppTheme.bodySmall.copyWith(color: textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Analyze button
                  PrimaryButton(
                    label: _isAnalyzing ? 'Analyzing...' : 'Analyze Evidence',
                    icon: _isAnalyzing ? Icons.hourglass_top_rounded : Icons.psychology_rounded,
                    onPressed: _isAnalyzing ? () {} : _startAnalysis,
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

  Widget _buildDropArea(BuildContext context, Color surface, Color primary,
      Color primaryGlow, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    if (_selectedFileBytes != null) {
      // Show selected file
      String sizeText;
      if (_selectedFileSize > 1024 * 1024) {
        sizeText = '${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        sizeText = '${(_selectedFileSize / 1024).toStringAsFixed(1)} KB';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: success.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.check_circle_rounded, color: success, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFileName ?? 'Unknown file',
                    style: AppTheme.subtitleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sizeText,
                    style: AppTheme.bodySmall.copyWith(color: textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: textMuted),
              onPressed: () {
                setState(() {
                  _selectedFileBytes = null;
                  _selectedFileName = null;
                  _selectedFileSize = 0;
                });
              },
            ),
          ],
        ),
      );
    }

    // Default drop area
    return GestureDetector(
      onTap: _pickFile,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withValues(alpha: 0.15),
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
                child: Icon(Icons.cloud_upload_rounded, size: 32, color: primary.withValues(alpha: 0.7)),
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
