import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  // ─── State ────────────────────────────────────────────────────────────────
  NationalStats _stats = NationalStats.empty();
  final Map<DashboardAnalysisType, AgentAnalysisResult> _analyses = {};
  List<RecentAnalysis> _recentAnalyses = [];

  bool _isStatsLoading = false;
  bool _isRecentLoading = false;
  bool _initialized = false;
  String? _statsError;

  // ─── Getters ──────────────────────────────────────────────────────────────
  NationalStats get stats => _stats;
  List<RecentAnalysis> get recentAnalyses => _recentAnalyses;
  bool get isStatsLoading => _isStatsLoading;
  bool get isRecentLoading => _isRecentLoading;
  bool get initialized => _initialized;
  String? get statsError => _statsError;

  AgentAnalysisResult? getAnalysis(DashboardAnalysisType type) =>
      _analyses[type];

  bool isAnalysisLoading(DashboardAnalysisType type) =>
      _analyses[type]?.isLoading ?? false;

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    await Future.wait([
      _loadStats(),
      _loadRecentAnalyses(),
    ]);
    _initialized = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _initialized = false;
    _analyses.clear();
    await initialize();
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    _isStatsLoading = true;
    _statsError = null;
    notifyListeners();
    try {
      _stats = await _service.fetchNationalStats();
    } catch (e) {
      _statsError = e.toString();
      _stats = NationalStats.empty();
    }
    _isStatsLoading = false;
    notifyListeners();
  }

  // ─── Recent sessions ──────────────────────────────────────────────────────
  Future<void> _loadRecentAnalyses() async {
    _isRecentLoading = true;
    notifyListeners();
    try {
      _recentAnalyses = await _service.fetchRecentAnalyses(limit: 5);
    } catch (_) {
      _recentAnalyses = [];
    }
    _isRecentLoading = false;
    notifyListeners();
  }

  // ─── Agentic analysis (per card) ──────────────────────────────────────────
  Future<void> runAnalysis(DashboardAnalysisType type) async {
    if (_analyses[type]?.isLoading == true) return;

    // Set loading state immediately
    _analyses[type] = AgentAnalysisResult.loading(type);
    notifyListeners();

    final result = await _service.runAgentAnalysis(type: type);
    _analyses[type] = result;
    notifyListeners();
  }

  /// Run all analysis cards in parallel
  Future<void> runAllAnalyses() async {
    // Mark all as loading
    for (final t in DashboardAnalysisType.values) {
      _analyses[t] = AgentAnalysisResult.loading(t);
    }
    notifyListeners();

    final results = await _service.runAllDashboardAnalyses();
    for (final r in results) {
      _analyses[r.type] = r;
    }
    notifyListeners();
  }

  void clearError() {
    _statsError = null;
    notifyListeners();
  }
}