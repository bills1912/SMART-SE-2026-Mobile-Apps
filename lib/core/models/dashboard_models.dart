import 'chat_models.dart';

// ─── Analysis type enum ───────────────────────────────────────────────────────

enum DashboardAnalysisType {
  sectorDistribution,
  provincialRanking,
  growthTrend,
  employmentImpact;

  String get label {
    switch (this) {
      case DashboardAnalysisType.sectorDistribution:
        return 'Distribusi Sektor';
      case DashboardAnalysisType.provincialRanking:
        return 'Peringkat Provinsi';
      case DashboardAnalysisType.growthTrend:
        return 'Tren Pertumbuhan';
      case DashboardAnalysisType.employmentImpact:
        return 'Dampak Ketenagakerjaan';
    }
  }

  String get icon {
    switch (this) {
      case DashboardAnalysisType.sectorDistribution:
        return '🏭';
      case DashboardAnalysisType.provincialRanking:
        return '🗺️';
      case DashboardAnalysisType.growthTrend:
        return '📈';
      case DashboardAnalysisType.employmentImpact:
        return '👥';
    }
  }

  String get description {
    switch (this) {
      case DashboardAnalysisType.sectorDistribution:
        return 'Persebaran unit usaha per sektor KBLI nasional';
      case DashboardAnalysisType.provincialRanking:
        return 'Top 10 provinsi berdasarkan jumlah usaha';
      case DashboardAnalysisType.growthTrend:
        return 'Tren pertumbuhan UMKM & usaha besar';
      case DashboardAnalysisType.employmentImpact:
        return 'Penyerapan tenaga kerja per sektor & skala';
    }
  }
}

// ─── National Stats ───────────────────────────────────────────────────────────

class NationalStats {
  final int totalUsaha;
  final int totalProvinsi;
  final int totalSektor;
  final int totalTenagaKerja;
  final double usahaGrowthPct;
  final double tkGrowthPct;
  final String lastUpdated;
  final bool isLive;

  NationalStats({
    required this.totalUsaha,
    required this.totalProvinsi,
    required this.totalSektor,
    required this.totalTenagaKerja,
    required this.usahaGrowthPct,
    required this.tkGrowthPct,
    required this.lastUpdated,
    required this.isLive,
  });

  factory NationalStats.fromJson(Map<String, dynamic> json) {
    final stats = json['data_stats'] ?? json['stats'] ?? json;
    return NationalStats(
      totalUsaha: _parseInt(stats['total_usaha'] ?? stats['total_businesses'] ?? 0),
      totalProvinsi: _parseInt(stats['total_provinces'] ?? stats['total_provinsi'] ?? 34),
      totalSektor: _parseInt(stats['total_sectors'] ?? stats['total_sektor'] ?? 17),
      totalTenagaKerja: _parseInt(stats['total_workers'] ?? stats['total_tenaga_kerja'] ?? 0),
      usahaGrowthPct: _parseDouble(stats['growth_pct'] ?? stats['usaha_growth'] ?? 0),
      tkGrowthPct: _parseDouble(stats['tk_growth_pct'] ?? 0),
      lastUpdated: stats['last_updated']?.toString() ?? 'N/A',
      isLive: true,
    );
  }

  factory NationalStats.fromHealthJson(Map<String, dynamic> json) {
    final stats = json['data_stats'] ?? {};
    return NationalStats(
      totalUsaha: _parseInt(stats['total_records'] ?? stats['total_usaha'] ?? 0),
      totalProvinsi: 34,
      totalSektor: 17,
      totalTenagaKerja: 0,
      usahaGrowthPct: 0,
      tkGrowthPct: 0,
      lastUpdated: json['last_scraping']?.toString() ?? 'N/A',
      isLive: json['status'] == 'healthy',
    );
  }

  factory NationalStats.empty() => NationalStats(
    totalUsaha: 0,
    totalProvinsi: 34,
    totalSektor: 17,
    totalTenagaKerja: 0,
    usahaGrowthPct: 0,
    tkGrowthPct: 0,
    lastUpdated: 'N/A',
    isLive: false,
  );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ─── Agent Analysis Result ────────────────────────────────────────────────────

enum AgentAnalysisStatus { idle, loading, success, error }

class AgentAnalysisResult {
  final DashboardAnalysisType type;
  final AgentAnalysisStatus status;
  final String message;
  final String sessionId;
  final List<VisualizationConfig> visualizations;
  final List<String> insights;
  final List<PolicyRecommendation> policies;
  final String? errorMessage;
  final DateTime fetchedAt;

  AgentAnalysisResult({
    required this.type,
    required this.status,
    required this.message,
    required this.sessionId,
    required this.visualizations,
    required this.insights,
    required this.policies,
    this.errorMessage,
    required this.fetchedAt,
  });

  factory AgentAnalysisResult.loading(DashboardAnalysisType type) =>
      AgentAnalysisResult(
        type: type,
        status: AgentAnalysisStatus.loading,
        message: '',
        sessionId: '',
        visualizations: [],
        insights: [],
        policies: [],
        fetchedAt: DateTime.now(),
      );

  factory AgentAnalysisResult.fromJson(
      Map<String, dynamic> json, DashboardAnalysisType type) {
    return AgentAnalysisResult(
      type: type,
      status: AgentAnalysisStatus.success,
      message: json['message']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      visualizations: json['visualizations'] != null && json['visualizations'] is List
          ? (json['visualizations'] as List)
          .map((v) => VisualizationConfig.fromJson(
          v is Map<String, dynamic> ? v : Map<String, dynamic>.from(v as Map)))
          .toList()
          : [],
      insights: json['insights'] != null && json['insights'] is List
          ? List<String>.from(json['insights'].map((e) => e.toString()))
          : [],
      policies: json['policies'] != null && json['policies'] is List
          ? (json['policies'] as List)
          .map((p) => PolicyRecommendation.fromJson(
          p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList()
          : [],
      fetchedAt: DateTime.now(),
    );
  }

  factory AgentAnalysisResult.error(DashboardAnalysisType type, String msg) =>
      AgentAnalysisResult(
        type: type,
        status: AgentAnalysisStatus.error,
        message: '',
        sessionId: '',
        visualizations: [],
        insights: [],
        policies: [],
        errorMessage: msg,
        fetchedAt: DateTime.now(),
      );

  bool get hasVisualizations => visualizations.isNotEmpty;
  bool get hasInsights => insights.isNotEmpty;
  bool get hasPolicies => policies.isNotEmpty;
  bool get isLoading => status == AgentAnalysisStatus.loading;
  bool get isSuccess => status == AgentAnalysisStatus.success;
  bool get isError => status == AgentAnalysisStatus.error;
}

// ─── Recent Analysis (from sessions) ─────────────────────────────────────────

class RecentAnalysis {
  final String sessionId;
  final String title;
  final DateTime updatedAt;
  final int messageCount;

  RecentAnalysis({
    required this.sessionId,
    required this.title,
    required this.updatedAt,
    required this.messageCount,
  });

  factory RecentAnalysis.fromJson(Map<String, dynamic> json) {
    return RecentAnalysis(
      sessionId: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Analisis',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messageCount: json['message_count'] is int
          ? json['message_count']
          : int.tryParse(json['message_count']?.toString() ?? '0') ?? 0,
    );
  }
}

// ─── Quick shortcut prompts ───────────────────────────────────────────────────

class QuickPrompt {
  final String label;
  final String prompt;
  final String icon;
  final String category;

  const QuickPrompt({
    required this.label,
    required this.prompt,
    required this.icon,
    required this.category,
  });
}

const kQuickPrompts = <QuickPrompt>[
  QuickPrompt(
    label: 'Sebaran Nasional',
    prompt: 'Tampilkan peta persebaran usaha di seluruh Indonesia berdasarkan data sensus ekonomi 2026',
    icon: '🗺️',
    category: 'Spasial',
  ),
  QuickPrompt(
    label: 'Top Sektor',
    prompt: 'Sektor ekonomi apa yang memiliki jumlah usaha terbanyak di Indonesia?',
    icon: '🏆',
    category: 'Sektor',
  ),
  QuickPrompt(
    label: 'UMKM Indonesia',
    prompt: 'Analisis kondisi UMKM Indonesia berdasarkan data sensus ekonomi 2026',
    icon: '🏪',
    category: 'UMKM',
  ),
  QuickPrompt(
    label: 'Ketimpangan Wilayah',
    prompt: 'Analisis ketimpangan ekonomi antara Jawa dan luar Jawa berdasarkan data sensus',
    icon: '⚖️',
    category: 'Spasial',
  ),
  QuickPrompt(
    label: 'Potensi Investasi',
    prompt: 'Provinsi mana yang memiliki potensi investasi terbaik berdasarkan data sensus ekonomi?',
    icon: '💰',
    category: 'Kebijakan',
  ),
  QuickPrompt(
    label: 'Tenaga Kerja',
    prompt: 'Analisis penyerapan tenaga kerja berdasarkan sektor dan skala usaha dari data sensus 2026',
    icon: '👷',
    category: 'Ketenagakerjaan',
  ),
];