import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../models/investigation.dart';
import '../../services/api_service.dart';
import '../../widgets/staggered_entry.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  HistoryStats _stats = HistoryStats(total: 0, highRisk: 0, mediumRisk: 0, lowRisk: 0);
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getHistory(),
        ApiService.getHistoryStats(),
      ]);

      if (mounted) {
        setState(() {
          _historyItems = results[0] as List<HistoryItem>;
          _stats = results[1] as HistoryStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load history';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _isLoading
                ? _buildLoading()
                : _error != null
                    ? _buildError()
                    : _buildContent(padding, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: AppTheme.bodyLarge),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadHistory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double padding, bool isDark) {
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;

    return RefreshIndicator(
      onRefresh: _loadHistory,
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
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.primary : AppColorsLight.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.primary : AppColorsLight.primary).withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('Investigation History', style: AppTheme.headingMedium),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                '${_historyItems.length} investigations completed',
                style: AppTheme.bodySmall.copyWith(
                  color: textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Stats row
            _buildStatsRow(context),
            const SizedBox(height: 28),

            // History list or empty state
            if (_historyItems.isEmpty)
              _buildEmptyState(context)
            else
              StaggeredEntry(
                staggerDelay: const Duration(milliseconds: 80),
                children: [
                  for (int i = 0; i < _historyItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistoryCard(context, _historyItems[i]),
                    ),
                ],
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(child: _statCard(context, '${_stats.total}', 'Total',
            isDark ? AppColors.primary : AppColorsLight.primary,
            isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, '${_stats.highRisk}', 'High Risk',
            isDark ? AppColors.highRisk : AppColorsLight.highRisk,
            isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(context, '${_stats.lowRisk}', 'Low Risk',
            isDark ? AppColors.lowRisk : AppColorsLight.lowRisk,
            isDark ? AppColors.lowRiskBg : AppColorsLight.lowRiskBg)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String value, String label, Color color, Color bgColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Text(value, style: AppTheme.headingMedium.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textTertiary
                      : AppColorsLight.textTertiary,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: textMuted),
          const SizedBox(height: 16),
          Text('No investigations yet', style: AppTheme.bodyLarge.copyWith(color: textMuted)),
          const SizedBox(height: 8),
          Text(
            'Upload an image or video to start your first analysis.',
            style: AppTheme.bodySmall.copyWith(color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.card : AppColorsLight.card;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textTertiary = isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Determine risk color based on level
    final riskLevel = item.riskLevel.toUpperCase();
    final riskColor = riskLevel == 'HIGH'
        ? (isDark ? AppColors.highRisk : AppColorsLight.highRisk)
        : riskLevel == 'MEDIUM'
            ? (isDark ? AppColors.mediumRisk : AppColorsLight.mediumRisk)
            : (isDark ? AppColors.lowRisk : AppColorsLight.lowRisk);
    final riskBg = riskLevel == 'HIGH'
        ? (isDark ? AppColors.highRiskBg : AppColorsLight.highRiskBg)
        : riskLevel == 'MEDIUM'
            ? (isDark ? AppColors.mediumRiskBg : AppColorsLight.mediumRiskBg)
            : (isDark ? AppColors.lowRiskBg : AppColorsLight.lowRiskBg);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          // Could navigate to results detail if needed
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // File icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: riskBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: riskColor.withOpacity(0.2)),
                ),
                child: Icon(
                  item.mediaCategory == 'video'
                      ? Icons.videocam_rounded
                      : Icons.image_rounded,
                  color: riskColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.filename,
                        style: AppTheme.subtitleMedium.copyWith(color: textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(item.formattedDate,
                            style: AppTheme.bodySmall.copyWith(
                                color: textTertiary, fontSize: 11)),
                        const SizedBox(width: 8),
                        Text('•',
                            style: AppTheme.bodySmall.copyWith(color: textMuted)),
                        const SizedBox(width: 8),
                        Text(item.mediaTypeLabel,
                            style: AppTheme.bodySmall.copyWith(
                                color: textTertiary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),

              // Risk score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.riskScore}',
                      style: AppTheme.headingSmall.copyWith(
                          color: riskColor, fontWeight: FontWeight.w800)),
                  Text('/ 100', style: AppTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
