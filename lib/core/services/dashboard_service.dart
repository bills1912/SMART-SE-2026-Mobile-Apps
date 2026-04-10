import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../models/dashboard_models.dart';

/// DashboardService
/// Fetches national statistics from the backend and invokes the
/// agentic analysis pipeline (same endpoint as chat but with a
/// structured prompt) so we get AI-generated insights & charts.
class DashboardService {
  static const String _baseUrl =
      'https://smart-se26-agentic-ai-production.up.railway.app/api';

  late final Dio _dio;

  DashboardService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getSecure('session_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // ─── 1. National Statistics (from scraper / DB stats endpoint) ───────────

  /// GET /api/analytics/dashboard  — direct DB aggregate
  Future<NationalStats> fetchNationalStats() async {
    try {
      final res = await _dio.get('/analytics/dashboard');
      return NationalStats.fromJson(res.data);
    } catch (_) {
      // Fallback: derive from health endpoint
      try {
        final health = await _dio.get('/health');
        return NationalStats.fromHealthJson(health.data);
      } catch (_) {
        return NationalStats.empty();
      }
    }
  }

  // ─── 2. Agentic Analysis (POST /api/chat with structured prompt) ──────────

  /// Calls the chat/agentic endpoint with a pre-built analysis prompt.
  /// The backend's analysis agent will run, return visualizations + insights.
  Future<AgentAnalysisResult> runAgentAnalysis({
    required DashboardAnalysisType type,
    String? sessionId,
  }) async {
    final prompt = _buildPrompt(type);
    try {
      final res = await _dio.post('/chat', data: {
        'message': prompt,
        if (sessionId != null && sessionId.isNotEmpty)
          'session_id': sessionId,
        'include_visualizations': true,
        'include_insights': true,
        'include_policies': true,
      });

      return AgentAnalysisResult.fromJson(res.data, type);
    } catch (e) {
      return AgentAnalysisResult.error(type, e.toString());
    }
  }

  /// Runs all four dashboard analysis cards in parallel.
  Future<List<AgentAnalysisResult>> runAllDashboardAnalyses() async {
    final types = DashboardAnalysisType.values;
    final futures = types.map((t) => runAgentAnalysis(type: t));
    return Future.wait(futures);
  }

  // ─── 3. Quick shortcut queries ────────────────────────────────────────────

  /// GET /api/sessions — recent sessions for "shortcut" cards
  Future<List<RecentAnalysis>> fetchRecentAnalyses({int limit = 5}) async {
    try {
      final res = await _dio.get('/sessions');
      final raw = res.data is List
          ? res.data as List
          : (res.data['sessions'] as List? ?? []);
      return raw
          .take(limit)
          .map((s) => RecentAnalysis.fromJson(s is Map<String, dynamic>
          ? s
          : Map<String, dynamic>.from(s as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Prompt builder ───────────────────────────────────────────────────────

  String _buildPrompt(DashboardAnalysisType type) {
    switch (type) {
      case DashboardAnalysisType.sectorDistribution:
        return 'Analisis distribusi unit usaha berdasarkan sektor ekonomi (KBLI) '
            'di seluruh Indonesia dari data Sensus Ekonomi 2026. '
            'Tampilkan dalam bentuk grafik, berikan insight utama dan '
            'rekomendasi kebijakan sektoral.';

      case DashboardAnalysisType.provincialRanking:
        return 'Buat peringkat 10 provinsi dengan jumlah unit usaha terbanyak '
            'berdasarkan data Sensus Ekonomi 2026. '
            'Analisis pola ketimpangan spasial antar wilayah dan '
            'berikan rekomendasi pemerataan ekonomi.';

      case DashboardAnalysisType.growthTrend:
        return 'Analisis tren pertumbuhan usaha mikro, kecil, menengah, dan besar '
            'berdasarkan data Sensus Ekonomi 2026. '
            'Identifikasi sektor dengan pertumbuhan tertinggi dan '
            'proyeksikan potensi ke depan.';

      case DashboardAnalysisType.employmentImpact:
        return 'Analisis dampak penyerapan tenaga kerja berdasarkan skala usaha '
            'dan sektor dari data Sensus Ekonomi 2026. '
            'Identifikasi sektor dengan potensi penyerapan tenaga kerja terbesar '
            'dan berikan rekomendasi kebijakan ketenagakerjaan.';
    }
  }
}