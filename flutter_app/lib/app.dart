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
                  return SlideUpRoute(page: const MainShell());
                case '/upload':
                  return SlideRightRoute(page: const UploadScreen());
                case '/analysis':
                  return FadeRoute(page: const AnalysisScreen());
                case '/results':
                  return ScaleUpRoute(page: const ResultsScreen());
                case '/evidence':
                  return SlideRightRoute(page: const EvidenceScreen());
                case '/report':
                  return SlideRightRoute(page: const ReportScreen());
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
