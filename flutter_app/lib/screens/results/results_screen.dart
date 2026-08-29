import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../models/investigation.dart';
import '../../widgets/risk_score_card.dart';
import '../../widgets/analysis_metric_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_entry.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final investigation = MockData.demoInvestigation;
    final padding = ResponsiveWrapper.padding(context);
    final isWide = ResponsiveWrapper.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text('Investigation Result'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: StaggeredEntry(
                staggerDelay: const Duration(milliseconds: 100),
                children: [
                  const SizedBox(height: 8),

                  // Risk Score Card
                  RiskScoreCard(
                    score: investigation.riskScore,
                    riskLevel: investigation.riskLevel,
                    label: 'Manipulation Risk Score',
                  ),
                  const SizedBox(height: 20),

                  // Assessment callout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.highRiskBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.highRisk.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.highRisk.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.highRisk,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Multiple signals associated with digital manipulation were detected.',
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section header
                  Text('Analysis Breakdown', style: AppTheme.headingSmall),
                  const SizedBox(height: 16),

                  // Metric cards
                  ...investigation.metrics.map(
                    (metric) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnalysisMetricCard(metric: metric),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CTA buttons
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'View Evidence',
                                icon: Icons.search_rounded,
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed('/evidence');
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Full Report',
                                icon: Icons.description_rounded,
                                isOutlined: true,
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed('/report');
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            PrimaryButton(
                              label: 'View Evidence',
                              icon: Icons.search_rounded,
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed('/evidence');
                              },
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Full Report',
                              icon: Icons.description_rounded,
                              isOutlined: true,
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed('/report');
                              },
                            ),
                          ],
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
}
