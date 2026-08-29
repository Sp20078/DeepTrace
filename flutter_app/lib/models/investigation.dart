enum RiskLevel { low, medium, high }

class AnalysisMetric {
  final String name;
  final int score;
  final String description;
  final String icon;

  const AnalysisMetric({
    required this.name,
    required this.score,
    required this.description,
    required this.icon,
  });
}

class SuspiciousTimestamp {
  final String time;
  final String label;
  final bool isHighAnomaly;

  const SuspiciousTimestamp({
    required this.time,
    required this.label,
    this.isHighAnomaly = false,
  });
}

class Finding {
  final int number;
  final String description;
  final bool isCritical;

  const Finding({
    required this.number,
    required this.description,
    this.isCritical = false,
  });
}

class Investigation {
  final String id;
  final String fileName;
  final String mediaType;
  final int analyzedFrames;
  final int riskScore;
  final RiskLevel riskLevel;
  final String assessment;
  final List<AnalysisMetric> metrics;
  final List<SuspiciousTimestamp> suspiciousTimestamps;
  final List<Finding> findings;
  final String conclusion;

  const Investigation({
    required this.id,
    required this.fileName,
    required this.mediaType,
    required this.analyzedFrames,
    required this.riskScore,
    required this.riskLevel,
    required this.assessment,
    required this.metrics,
    required this.suspiciousTimestamps,
    required this.findings,
    required this.conclusion,
  });

  static RiskLevel _riskFromScore(int score) {
    if (score >= 70) return RiskLevel.high;
    if (score >= 40) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.low:
        return 'LOW RISK';
    }
  }
}

class RecentInvestigation {
  final String fileName;
  final int riskScore;
  final RiskLevel riskLevel;

  const RecentInvestigation({
    required this.fileName,
    required this.riskScore,
    required this.riskLevel,
  });

  String get riskLabel => Investigation._riskLevel == riskLevel
      ? Investigation._riskLabel(riskLevel)
      : _label(riskLevel);

  String _label(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.low:
        return 'LOW RISK';
    }
  }
}

class MockData {
  MockData._();

  static const Investigation demoInvestigation = Investigation(
    id: 'DF-2026-00142',
    fileName: 'suspect_video.mp4',
    mediaType: 'Video',
    analyzedFrames: 54,
    riskScore: 87,
    riskLevel: RiskLevel.high,
    assessment: 'HIGH RISK',
    metrics: [
      AnalysisMetric(
        name: 'Visual Analysis',
        score: 82,
        description: 'Potential facial and visual artifacts detected.',
        icon: '👁️',
      ),
      AnalysisMetric(
        name: 'Temporal Analysis',
        score: 91,
        description: 'Frame-to-frame inconsistencies detected.',
        icon: '⏱️',
      ),
      AnalysisMetric(
        name: 'Metadata Analysis',
        score: 40,
        description: 'No strong metadata evidence of manipulation.',
        icon: '📋',
      ),
      AnalysisMetric(
        name: 'Face Analysis',
        score: 76,
        description: 'Potential facial boundary inconsistencies detected.',
        icon: '🧑',
      ),
    ],
    suspiciousTimestamps: [
      SuspiciousTimestamp(time: '00:00', label: 'Start', isHighAnomaly: false),
      SuspiciousTimestamp(time: '00:08', label: 'Normal', isHighAnomaly: false),
      SuspiciousTimestamp(time: '00:14', label: 'High anomaly detected', isHighAnomaly: true),
      SuspiciousTimestamp(time: '00:20', label: 'End', isHighAnomaly: false),
    ],
    findings: [
      Finding(number: 1, description: 'Facial boundary inconsistency detected', isCritical: true),
      Finding(number: 2, description: 'Temporal anomaly detected between 00:13–00:16', isCritical: true),
      Finding(number: 3, description: 'Unusual visual artifacts detected', isCritical: false),
      Finding(number: 4, description: 'Metadata provides insufficient provenance information', isCritical: false),
    ],
    conclusion:
        'The analyzed media exhibits multiple signals associated with digital manipulation.',
  );

  static const List<RecentInvestigation> recentInvestigations = [
    RecentInvestigation(
      fileName: 'suspect_video.mp4',
      riskScore: 87,
      riskLevel: RiskLevel.high,
    ),
    RecentInvestigation(
      fileName: 'portrait.jpg',
      riskScore: 18,
      riskLevel: RiskLevel.low,
    ),
    RecentInvestigation(
      fileName: 'interview_clip.mp4',
      riskScore: 54,
      riskLevel: RiskLevel.medium,
    ),
  ];
}
