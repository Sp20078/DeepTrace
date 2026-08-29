import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../services/api_service.dart';
import '../results/results_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final File? file;
  final String? fileName;

  const AnalysisScreen({super.key, this.file, this.fileName});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  int _currentStep = -1;
  bool _isComplete = false;
  bool _hasError = false;
  String? _errorMsg;
  late AnimationController _scanController;
  Timer? _progressTimer;

  final List<_AnalysisStep> _steps = [
    _AnalysisStep('File integrity verified'),
    _AnalysisStep('Media metadata extraction'),
    _AnalysisStep('Face detection'),
    _AnalysisStep('AI model inference'),
    _AnalysisStep('Result aggregation'),
    _AnalysisStep('Evidence compilation'),
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
    if (widget.file == null) {
      setState(() {
        _hasError = true;
        _errorMsg = 'No file provided for analysis.';
      });
      return;
    }

    // Simulate step progress while waiting for API
    const totalDuration = Duration(seconds: 30);
    const stepInterval = Duration(milliseconds: 4000);
    final startTime = DateTime.now();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final p = (elapsed.inMilliseconds / totalDuration.inMilliseconds)
          .clamp(0.0, 0.95); // Don't reach 100% until API responds
      final stepIndex = (elapsed.inMilliseconds / stepInterval.inMilliseconds)
          .floor()
          .clamp(0, _steps.length - 1);

      if (mounted && !_hasError) {
        setState(() {
          _progress = p;
          _currentStep = stepIndex;
        });
      }
    });

    // Call the real API
    try {
      final result = await ApiService.analyzeFile(widget.file!);

      _progressTimer?.cancel();

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _currentStep = _steps.length;
          _isComplete = true;
        });

        // Navigate to results after brief pause
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ResultsScreen(analysisResult: result),
              ),
            );
          }
        });
      }
    } on ApiException catch (e) {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = e.message;
        });
      }
    } catch (e) {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = 'Connection error. Is the backend running?\n$e';
        });
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  Color _bg(BuildContext c) => _isDark(c) ? AppColors.background : AppColorsLight.background;
  Color _card(BuildContext c) => _isDark(c) ? AppColors.card : AppColorsLight.card;
  Color _cardBorder(BuildContext c) => _isDark(c) ? AppColors.cardBorder : AppColorsLight.cardBorder;
  Color _surface(BuildContext c) => _isDark(c) ? AppColors.surface : AppColorsLight.surface;
  Color _primary(BuildContext c) => _isDark(c) ? AppColors.primary : AppColorsLight.primary;
  Color _primaryGlow(BuildContext c) => _isDark(c) ? AppColors.primaryGlow : AppColorsLight.primaryGlow;
  Color _success(BuildContext c) => _isDark(c) ? AppColors.success : AppColorsLight.success;
  Color _highRisk(BuildContext c) => _isDark(c) ? AppColors.highRisk : AppColorsLight.highRisk;
  Color _divider(BuildContext c) => _isDark(c) ? AppColors.divider : AppColorsLight.divider;
  Color _textPrimary(BuildContext c) => _isDark(c) ? AppColors.textPrimary : AppColorsLight.textPrimary;
  Color _textSecondary(BuildContext c) => _isDark(c) ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color _textTertiary(BuildContext c) => _isDark(c) ? AppColors.textTertiary : AppColorsLight.textTertiary;
  Color _textMuted(BuildContext c) => _isDark(c) ? AppColors.textMuted : AppColorsLight.textMuted;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final fileName = widget.fileName ?? 'unknown_file';

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
                      fileName,
                      style: AppTheme.bodyMedium.copyWith(color: _textTertiary(context)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildMediaPreview(context),
                  const SizedBox(height: 28),
                  _buildProgressSection(context),
                  const SizedBox(height: 28),
                  _buildChecklistCard(context),
                  const SizedBox(height: 28),

                  // Error display
                  if (_hasError)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _highRisk(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _highRisk(context).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: _highRisk(context), size: 20),
                              const SizedBox(width: 10),
                              Text('Analysis Failed', style: AppTheme.subtitleMedium.copyWith(color: _highRisk(context))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(_errorMsg ?? 'Unknown error',
                              style: AppTheme.bodyMedium.copyWith(color: _textSecondary(context), fontSize: 13)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _hasError = false;
                                      _errorMsg = null;
                                      _progress = 0;
                                      _currentStep = -1;
                                      _isComplete = false;
                                    });
                                    _startAnalysis();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary(context),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Go Back'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                color: _hasError
                    ? _highRisk(context)
                    : (_isComplete ? _success(context) : _primary(context)),
                boxShadow: [
                  BoxShadow(
                    color: (_hasError
                            ? _highRisk(context)
                            : (_isComplete ? _success(context) : _primary(context)))
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
            Icon(Icons.videocam_rounded, size: 48, color: _textMuted(context).withOpacity(0.4)),

            // Scan line
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Positioned(
                  top: 0, left: 0, right: 0,
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

            Positioned(top: 10, left: 10, child: _cornerBracket(context)),
            Positioned(top: 10, right: 10, child: _cornerBracket(context, mirror: true)),
            Positioned(bottom: 10, left: 10, child: _cornerBracket(context, flip: true)),
            Positioned(bottom: 10, right: 10, child: _cornerBracket(context, mirror: true, flip: true)),

            // Status badge
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _hasError
                      ? _highRisk(context).withOpacity(0.15)
                      : _isComplete
                          ? _success(context).withOpacity(0.15)
                          : _primaryGlow(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _hasError
                        ? _highRisk(context).withOpacity(0.3)
                        : _isComplete
                            ? _success(context).withOpacity(0.3)
                            : p.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasError)
                      Icon(Icons.error_outline_rounded, size: 12, color: _highRisk(context))
                    else if (!_isComplete)
                      SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: p),
                      )
                    else
                      Icon(Icons.check_rounded, size: 12, color: _success(context)),
                    const SizedBox(width: 6),
                    Text(
                      _hasError ? 'FAILED' : (_isComplete ? 'COMPLETE' : 'ANALYZING'),
                      style: AppTheme.labelMedium.copyWith(
                        color: _hasError
                            ? _highRisk(context)
                            : _isComplete ? _success(context) : p,
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
      width: 20, height: 20,
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
              Text(_hasError ? 'Analysis Failed' : (_isComplete ? 'Analysis Complete' : 'Analyzing...'),
                  style: AppTheme.subtitleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _hasError
                      ? _highRisk(context).withOpacity(0.1)
                      : _isComplete ? s.withOpacity(0.1) : pg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage%',
                  style: AppTheme.labelMedium.copyWith(
                    color: _hasError ? _highRisk(context) : (_isComplete ? s : p),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                  _hasError ? _highRisk(context) : (_isComplete ? s : p)),
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
              width: 20, height: 20,
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
          if (isDone) Icon(Icons.check_rounded, color: s, size: 16),
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
