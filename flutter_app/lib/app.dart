import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/navigation/page_transitions.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/upload/upload_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/results/results_screen.dart';
import 'screens/evidence/evidence_screen.dart';
import 'screens/report/report_screen.dart';
import 'services/api_service.dart';

class DeepTraceApp extends StatefulWidget {
  const DeepTraceApp({super.key});

  @override
  State<DeepTraceApp> createState() => _DeepTraceAppState();
}

class _DeepTraceAppState extends State<DeepTraceApp> {
  final _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeNotifier(
      themeProvider: _themeProvider,
      child: AnimatedBuilder(
        animation: _themeProvider,
        builder: (context, _) {
          return MaterialApp(
            title: 'DEEPTRACE',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeProvider.themeMode,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return FadeRoute(page: const SplashScreen());
                case '/dashboard':
                  return CinematicRoute(page: const MainShell());
                case '/upload':
                  return SlideRightRoute(page: const UploadScreen());
                case '/analysis':
                  final args = settings.arguments;
                  if (args is Map<String, dynamic>) {
                    return FadeRoute(page: AnalysisScreen(
                      fileBytes: args['fileBytes'],
                      fileName: args['fileName'],
                    ));
                  }
                  return FadeRoute(page: const AnalysisScreen());
                case '/results':
                  final resultArgs = settings.arguments;
                  if (resultArgs is AnalysisResult) {
                    return ScaleUpRoute(page: ResultsScreen(analysisResult: resultArgs));
                  }
                  return FadeRoute(page: const UploadScreen());
                case '/evidence':
                  final evidenceArgs = settings.arguments;
                  if (evidenceArgs is AnalysisResult) {
                    return SlideRightRoute(page: EvidenceScreen(analysisResult: evidenceArgs));
                  }
                  return FadeRoute(page: const UploadScreen());
                case '/report':
                  final reportArgs = settings.arguments;
                  if (reportArgs is AnalysisResult) {
                    return SlideRightRoute(page: ReportScreen(analysisResult: reportArgs));
                  }
                  return FadeRoute(page: const UploadScreen());
                default:
                  return FadeRoute(page: const SplashScreen());
              }
            },
          );
        },
      ),
    );
  }
}
