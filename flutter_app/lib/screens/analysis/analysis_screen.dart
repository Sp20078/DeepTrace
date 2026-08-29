import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  int _currentStep = -1;
  bool _isComplete = false;
  late AnimationController _scanController;

  final List<_AnalysisStep> _steps = [
    _AnalysisStep('File integrity verified', true),
    _AnalysisStep('Metadata extraction', true),
    _AnalysisStep('Face detection', true),
    _AnalysisStep('Visual artifact analysis', true),
    _AnalysisStep('Temporal analysis', false),
    _AnalysisStep('Evidence correlation', false),
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startAnalysis();
  }

  void _startAnalysis() async {
    const totalDuration = Duration(milliseconds: 5000);
    const stepInterval = Duration(milliseconds: 800);
    final startTime = DateTime.now();

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final p = (elapsed.inMilliseconds / totalDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      final stepIndex = (elapsed.inMilliseconds / stepInterval.inMilliseconds)
          .floor()
          .clamp(0, _steps.length - 1);

      if (mounted) {
        setState(() {
          _progress = p;
          _currentStep = stepIndex;
        });
      }

      if (p >= 1.0) {
        timer.cancel();
        setState(() {
          _isComplete = true;
          _currentStep = _steps.length;
        });
        Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/results');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              Text(
                'Analyzing Evidence',
                style: AppTheme.headingMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'suspect_video.mp4',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),

              const SizedBox(height: 32),

              // Media preview placeholder
              _buildMediaPreview(),
              const SizedBox(height: 32),

              // Progress section
              _buildProgressSection(),
              const SizedBox(height: 28),

              // Checklist
              _buildChecklist(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder
          Icon(
            Icons.videocam_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),

          // Scan line animation
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    180 * _scanController.value,
                  ),
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // "ANALYZING" overlay
          if (!_isComplete)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ANALYZING',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final percentage = (_progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isComplete ? 'Analysis Complete' : 'Analyzing…',
              style: AppTheme.subtitleMedium,
            ),
            Text(
              '$percentage%',
              style: AppTheme.subtitleMedium.copyWith(
                color: _isComplete ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              _isComplete ? AppColors.success : AppColors.primary,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist() {
    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++)
          _buildCheckItem(i),
      ],
    );
  }

  Widget _buildCheckItem(int index) {
    final step = _steps[index];
    final bool isDone = index < _currentStep;
    final bool isCurrent = index == _currentStep && !_isComplete;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Status icon
          if (isDone)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            )
          else if (isCurrent)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Icon(
              Icons.radio_button_unchecked_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),

          const SizedBox(width: 14),

          // Label
          Expanded(
            child: Text(
              step.label,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                color: isDone
                    ? AppColors.textSecondary
                    : isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),

          if (isDone)
            Text(
              '✓',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.success,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalysisStep {
  final String label;
  final bool preCompleted;

  const _AnalysisStep(this.label, this.preCompleted);
}
