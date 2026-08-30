import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Configuration for the API service.
/// Change baseUrl when deploying to a different host.
class ApiConfig {
  // Local development — FastAPI backend
  // Use localhost (not 127.0.0.1) for better browser compatibility
  static const String baseUrl = 'http://localhost:8000';
  static const Duration timeout = Duration(seconds: 120);
}

/// Data model for analysis results.
class AnalysisResult {
  final String analysisId;
  final String status;
  final String mediaType;
  final String mediaCategory;
  final String filename;
  final String prediction;
  final double score;
  final String message;
  final int facesDetected;
  final int framesAnalyzed;
  final List<dynamic> suspiciousFrames;
  final List<dynamic> suspiciousSegments;
  final List<dynamic> findings;
  final Map<String, dynamic> mediaInfo;
  final String fileHash;
  final String model;
  final String timestamp;
  final List<dynamic> frameResults;

  AnalysisResult({
    required this.analysisId,
    required this.status,
    required this.mediaType,
    required this.mediaCategory,
    required this.filename,
    required this.prediction,
    required this.score,
    required this.message,
    required this.facesDetected,
    required this.framesAnalyzed,
    required this.suspiciousFrames,
    required this.suspiciousSegments,
    required this.findings,
    required this.mediaInfo,
    required this.fileHash,
    required this.model,
    required this.timestamp,
    required this.frameResults,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      analysisId: json['analysis_id'] ?? '',
      status: json['status'] ?? 'failed',
      mediaType: json['media_type'] ?? '',
      mediaCategory: json['media_category'] ?? '',
      filename: json['filename'] ?? '',
      prediction: json['prediction'] ?? 'Inconclusive',
      score: (json['score'] ?? 0).toDouble(),
      message: json['message'] ?? '',
      facesDetected: json['faces_detected'] ?? 0,
      framesAnalyzed: json['frames_analyzed'] ?? 0,
      suspiciousFrames: json['suspicious_frames'] ?? [],
      suspiciousSegments: json['suspicious_segments'] ?? [],
      findings: json['findings'] ?? [],
      mediaInfo: json['media_info'] ?? {},
      fileHash: json['file_hash'] ?? '',
      model: json['model'] ?? '',
      timestamp: json['timestamp'] ?? '',
      frameResults: json['frame_results'] ?? [],
    );
  }

  int get riskScore => score.round();

  String get riskLevel {
    if (score >= 65) return 'HIGH';
    if (score >= 35) return 'MEDIUM';
    return 'LOW';
  }

  bool get isHighRisk => score >= 65;
  bool get isMediumRisk => score >= 35 && score < 65;
  bool get isLowRisk => score < 35;
}

/// History item from the API.
class HistoryItem {
  final String analysisId;
  final String filename;
  final String mediaType;
  final String mediaCategory;
  final String prediction;
  final int riskScore;
  final String riskLevel;
  final int facesDetected;
  final int framesAnalyzed;
  final String timestamp;
  final String model;

  HistoryItem({
    required this.analysisId,
    required this.filename,
    required this.mediaType,
    required this.mediaCategory,
    required this.prediction,
    required this.riskScore,
    required this.riskLevel,
    required this.facesDetected,
    required this.framesAnalyzed,
    required this.timestamp,
    required this.model,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      analysisId: json['analysis_id'] ?? '',
      filename: json['filename'] ?? '',
      mediaType: json['media_type'] ?? '',
      mediaCategory: json['media_category'] ?? 'image',
      prediction: json['prediction'] ?? '',
      riskScore: json['risk_score'] ?? 0,
      riskLevel: json['risk_level'] ?? 'MINIMAL',
      facesDetected: json['faces_detected'] ?? 0,
      framesAnalyzed: json['frames_analyzed'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      model: json['model'] ?? '',
    );
  }

  DateTime? get dateTime {
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  String get formattedDate {
    final dt = dateTime;
    if (dt == null) return timestamp;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String get mediaTypeLabel => mediaCategory == 'video' ? 'Video' : 'Image';
}

/// History statistics from the API.
class HistoryStats {
  final int total;
  final int highRisk;
  final int mediumRisk;
  final int lowRisk;

  HistoryStats({
    required this.total,
    required this.highRisk,
    required this.mediumRisk,
    required this.lowRisk,
  });

  factory HistoryStats.fromJson(Map<String, dynamic> json) {
    return HistoryStats(
      total: json['total'] ?? 0,
      highRisk: json['high_risk'] ?? 0,
      mediumRisk: json['medium_risk'] ?? 0,
      lowRisk: json['low_risk'] ?? 0,
    );
  }
}

/// API service for communicating with the DeepTrace backend.
class ApiService {
  /// Analyze a media file — accepts Uint8List bytes (works on web + mobile).
  static Future<AnalysisResult> analyzeFile(Uint8List fileBytes, {String? fileName}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName ?? 'uploaded_file'),
    );

    // Send with timeout
    final streamedResponse = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return AnalysisResult.fromJson(json);
    } else if (response.statusCode == 400) {
      final json = jsonDecode(response.body);
      throw ApiException(
        json['detail'] ?? 'Unsupported file format',
        statusCode: 400,
      );
    } else {
      throw ApiException(
        'Server error: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Get analysis history.
  static Future<List<HistoryItem>> getHistory({int limit = 50}) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/history?limit=$limit'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> items = json['history'] ?? [];
        return items.map((item) => HistoryItem.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get history statistics.
  static Future<HistoryStats> getHistoryStats() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/history/stats'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return HistoryStats.fromJson(json);
      }
    } catch (_) {}
    return HistoryStats(total: 0, highRisk: 0, mediumRisk: 0, lowRisk: 0);
  }

  /// Get PDF report download URL.
  static String getReportUrl(String analysisId) {
    return '${ApiConfig.baseUrl}/history/$analysisId/report';
  }

  /// Check if the backend server is reachable.
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
