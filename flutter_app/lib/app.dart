import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/upload/upload_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/results/results_screen.dart';
import 'screens/evidence/evidence_screen.dart';
import 'screens/report/report_screen.dart';

class DeepTraceApp extends StatelessWidget {
  const DeepTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEEPTRACE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/upload': (context) => const UploadScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/results': (context) => const ResultsScreen(),
        '/evidence': (context) => const EvidenceScreen(),
        '/report': (context) => const ReportScreen(),
      },
    );
  }
}
