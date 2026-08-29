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

  // Theme helpers
  bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  Color _bg(BuildContext c) => _isDark(c) ? AppColors.background : AppColorsLight.background;
  Color _card(BuildContext c) => _isDark(c) ? AppColors.card : AppColorsLight.card;
  Color _cardBorder(BuildContext c) => _isDark(c) ? AppColors.cardBorder : AppColorsLight.cardBorder;
  Color _surface(BuildContext c) => _isDark(c) ? AppColors.surface : AppColorsLight.surface;
  Color _primary(BuildContext c) => _isDark(c) ? AppColors.primary : AppColorsLight.primary;
  Color _primaryGlow(BuildContext c) => _isDark(c) ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
  Color _success(BuildContext c) => _isDark(c) ? AppColors.success : AppColorsLight.success;
  Color _divider(BuildContext c) => _isDark(c) ? AppColors.divider : AppColorsLight.divider;
  Color _textPrimary(BuildContext c) => _isDark(c) ? AppColors.textPrimary : AppColorsLight.textPrimary;
  Color _textSecondary(BuildContext c) => _isDark(c) ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color _textTertiary(BuildContext c) => _isDark(c) ? AppColors.textTertiary : AppColorsLight.textTertiary;
  Color _textMuted(BuildContext c) => _isDark(c) ? AppColors.textMuted : AppColorsLight.textMuted;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);

    return Scaffold(
      backgroundColor: _bg(context),
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
                  _buildHeader(context),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      'suspect_video.mp4',
                      style: AppTheme.bodyMedium.copyWith(color: _textTertiary(context)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildMediaPreview(context),
                  const SizedBox(height: 28),
                  _buildProgressSection(context),
                  const SizedBox(height: 28),
                  _buildChecklistCard(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isComplete ? _success(context) : _primary(context),
                boxShadow: [
                  BoxShadow(
                    color: (_isComplete ? _success(context) : _primary(context))
                        .withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Text('Analyzing Evidence', style: AppTheme.headingMedium),
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    final p = _primary(context);
    final s = _surface(context);
    final cb = _cardBorder(context);
    final tm = _textMuted(context);

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: s,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cb, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size.infinite, painter: _AnalysisGridPainter(color: p)),
            Icon(Icons.videocam_rounded, size: 48, color: tm.withOpacity(0.4)),

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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, p, Colors.transparent],
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
                    offset: Offset(0, 200 * _scanController.value - 20),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, p.withOpacity(0.08)],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            Positioned(top: 10, left: 10, child: _cornerBracket(context)),
            Positioned(top: 10, right: 10, child: _cornerBracket(context, mirror: true)),
            Positioned(bottom: 10, left: 10, child: _cornerBracket(context, flip: true)),
            Positioned(bottom: 10, right: 10, child: _cornerBracket(context, mirror: true, flip: true)),

            // Status badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isComplete ? _success(context).withOpacity(0.15) : _primaryGlow(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isComplete
                        ? _success(context).withOpacity(0.3)
                        : p.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isComplete)
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: p),
                      )
                    else
                      Icon(Icons.check_rounded, size: 12, color: _success(context)),
                    const SizedBox(width: 6),
                    Text(
                      _isComplete ? 'COMPLETE' : 'ANALYZING',
                      style: AppTheme.labelMedium.copyWith(
                        color: _isComplete ? _success(context) : p,
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

  Widget _cornerBracket(BuildContext context, {bool mirror = false, bool flip = false}) {
    final p = _primary(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: !flip ? BorderSide(color: p, width: 1.5) : BorderSide.none,
          bottom: flip ? BorderSide(color: p, width: 1.5) : BorderSide.none,
          left: !mirror ? BorderSide(color: p, width: 1.5) : BorderSide.none,
          right: mirror ? BorderSide(color: p, width: 1.5) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final percentage = (_progress * 100).round();
    final p = _primary(context);
    final s = _success(context);
    final pg = _primaryGlow(context);
    final d = _divider(context);
    final cb = _cardBorder(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cb),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isComplete ? 'Analysis Complete' : 'Analyzing…',
                  style: AppTheme.subtitleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isComplete ? s.withOpacity(0.1) : pg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage%',
                  style: AppTheme.labelMedium.copyWith(
                    color: _isComplete ? s : p,
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
              backgroundColor: d,
              valueColor: AlwaysStoppedAnimation<Color>(_isComplete ? s : p),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(BuildContext context) {
    final cb = _cardBorder(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cb),
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
    final p = _primary(context);
    final s = _success(context);
    final pg = _primaryGlow(context);
    final tp = _textPrimary(context);
    final ts = _textSecondary(context);
    final tm = _textMuted(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? pg.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (isDone)
            Icon(Icons.check_circle_rounded, color: s, size: 20)
          else if (isCurrent)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: p),
            )
          else
            Icon(Icons.radio_button_unchecked_rounded, color: tm, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              step.label,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                color: isDone ? ts : isCurrent ? tp : tm,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: tm,
              ),
            ),
          ),
          if (isDone)
            Icon(Icons.check_rounded, color: s, size: 16),
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
  final Color color;
  _AnalysisGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03)
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
