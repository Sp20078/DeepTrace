import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../widgets/staggered_entry.dart';

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
  Timer? _analysisTimer;

  final List<_AnalysisStep> _steps = [
    _AnalysisStep('File integrity verified'),
    _AnalysisStep('Metadata extraction'),
    _AnalysisStep('Face detection'),
    _AnalysisStep('Visual artifact analysis'),
    _AnalysisStep('Temporal analysis'),
    _AnalysisStep('Evidence correlation'),
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

    _analysisTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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
    _analysisTimer?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isComplete
                              ? AppColors.success
                              : AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (_isComplete
                                      ? AppColors.success
                                      : AppColors.primary)
                                  .withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Analyzing Evidence', style: AppTheme.headingMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      'suspect_video.mp4',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Media preview with scan
                  _buildMediaPreview(),
                  const SizedBox(height: 28),

                  // Progress
                  _buildProgressSection(),
                  const SizedBox(height: 28),

                  // Checklist in a card
                  _buildChecklistCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Grid background
            CustomPaint(
              size: Size.infinite,
              painter: _AnalysisGridPainter(),
            ),

            // Placeholder icon
            Icon(
              Icons.videocam_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.4),
            ),

            // Scan line
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, 200 * _scanController.value),
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

            // Scan glow trail
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(
                        0, 200 * _scanController.value - 20),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withOpacity(0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Corner brackets
            Positioned(top: 10, left: 10, child: _cornerBracket()),
            Positioned(
                top: 10,
                right: 10,
                child: _cornerBracket(mirror: true)),
            Positioned(
                bottom: 10,
                left: 10,
                child: _cornerBracket(flip: true)),
            Positioned(
                bottom: 10,
                right: 10,
                child: _cornerBracket(mirror: true, flip: true)),

            // "ANALYZING" / "COMPLETE" badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isComplete
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isComplete
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isComplete)
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      Icon(Icons.check_rounded,
                          size: 12, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      _isComplete ? 'COMPLETE' : 'ANALYZING',
                      style: AppTheme.labelMedium.copyWith(
                        color: _isComplete
                            ? AppColors.success
                            : AppColors.primary,
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
      ),
    );
  }

  Widget _cornerBracket({bool mirror = false, bool flip = false}) {
    return Container(
      width: 20,
      height: 20,
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

  Widget _buildProgressSection() {
    final percentage = (_progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isComplete ? 'Analysis Complete' : 'Analyzing…',
                style: AppTheme.subtitleMedium,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isComplete
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage%',
                  style: AppTheme.labelMedium.copyWith(
                    color: _isComplete
                        ? AppColors.success
                        : AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analysis Steps', style: AppTheme.subtitleMedium),
          const SizedBox(height: 16),
          for (int i = 0; i < _steps.length; i++) _buildCheckItem(i),
        ],
      ),
    );
  }

  Widget _buildCheckItem(int index) {
    final step = _steps[index];
    final bool isDone = index < _currentStep;
    final bool isCurrent = index == _currentStep && !_isComplete;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primaryGlow.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (isDone)
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20)
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
            Icon(Icons.radio_button_unchecked_rounded,
                color: AppColors.textMuted, size: 20),

          const SizedBox(width: 14),

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
                decoration:
                    isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),

          if (isDone)
            Icon(Icons.check_rounded,
                color: AppColors.success, size: 16),
        ],
      ),
    );
  }
}

class _AnalysisStep {
  final String label;
  const _AnalysisStep(this.label);
}

class _AnalysisGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
