import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import '../services/spatial_analysis_service.dart';
import '../models/spatial_analysis_models.dart';
import 'dart:convert';

/// ChatProvider — manages chat sessions, messages, and spatial analysis.
class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;
  final SpatialAnalysisService _spatialService = SpatialAnalysisService();

  ChatSession? _currentSession;
  List<ChatSession> _sessions = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  HealthStatus? _healthStatus;
  bool _initialized = false;

  // Spatial analysis results keyed by MESSAGE ID (local frontend ID).
  // Repopulated from persistent storage on every session load.
  final Map<String, SpatialAnalysisResult> _spatialResults = {};

  // ─────────────────────────────────────────────────────────────────────────
  // PERSISTENCE STRATEGY
  //
  // The backend assigns its own IDs to messages, so after reload the message
  // IDs differ from the local IDs used as keys in _spatialResults.
  //
  // Solution: persist the USER QUERY keyed by
  //   "sq__{sessionId}__{aiMsgIndex}"
  // where aiMsgIndex is the 0-based position of the AI message among all AI
  // messages in the session.  Position is stable across reloads.
  //
  // On restore: for each AI message at index i, look up the stored query,
  // regenerate the SpatialAnalysisResult from SpatialMockData, and map it
  // to the *backend* message ID so getSpatialResult(msg.id) works.
  // ─────────────────────────────────────────────────────────────────────────
  static const String _sqPrefix = 'sq__';

  ChatProvider(this._apiService, this._authProvider) {
    _authProvider.addListener(_onAuthChanged);
    _init();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    print('[ChatProvider] Auth changed: ${_authProvider.isAuthenticated}');
    if (_authProvider.isAuthenticated) {
      loadSessions();
    } else {
      _sessions = [];
      _currentSession = null;
      _spatialResults.clear();
      notifyListeners();
    }
  }

  // ─── Getters ──────────────────────────────────────────────────────────────
  ChatSession? get currentSession => _currentSession;
  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  HealthStatus? get healthStatus => _healthStatus;
  bool get isBackendAvailable => _healthStatus?.isHealthy ?? false;
  String get scrapingStatus => _healthStatus?.scrapingStatus ?? 'idle';
  Map<String, SpatialAnalysisResult> get spatialResults => _spatialResults;

  SpatialAnalysisResult? getSpatialResult(String messageId) =>
      _spatialResults[messageId];

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await checkBackendStatus();
    if (_authProvider.isAuthenticated) await loadSessions();
  }

  Future<void> refreshAfterLogin() async {
    await checkBackendStatus();
    await loadSessions();
  }

  Future<void> checkBackendStatus() async {
    try {
      final health = await _apiService.getHealth();
      _healthStatus = HealthStatus.fromJson(health);
    } catch (e) {
      _healthStatus = null;
    }
    notifyListeners();
  }

  Future<void> loadSessions() async {
    if (!_authProvider.isAuthenticated) {
      _sessions = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _sessions = await _apiService.getSessions();
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat sesi chat';
    }
    _isLoading = false;
    notifyListeners();
  }

  void createNewChat() {
    _currentSession = ChatSession(
      id: '',
      userId: _authProvider.user?.userId,
      title: 'Analisis Sensus Baru',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> switchToSession(String sessionId) async {
    if (_currentSession?.id == sessionId) return;
    _isLoading = true;
    notifyListeners();
    try {
      final cached = _sessions.firstWhere(
            (s) => s.id == sessionId,
        orElse: () => ChatSession(
            id: sessionId,
            title: '',
            messages: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()),
      );
      if (cached.messages.isNotEmpty) {
        _currentSession = cached;
        _rebuildSpatialResultsForSession(cached);
        notifyListeners();
      }

      final session = await _apiService.getSession(sessionId);
      _currentSession = session;
      // Rebuild with the fully-loaded session (real backend message IDs)
      _rebuildSpatialResultsForSession(session);

      final idx = _sessions.indexWhere((s) => s.id == sessionId);
      if (idx >= 0) _sessions[idx] = session;
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat sesi';
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Persistence helpers ──────────────────────────────────────────────────

  String _storageKey(String sessionId, int aiMsgIndex) =>
      '$_sqPrefix${sessionId}__$aiMsgIndex';

  /// Saves the user query string at position [aiMsgIndex] (0-based, AI only).
  Future<void> _persistSpatialQuery(
      String sessionId, int aiMsgIndex, String userQuery) async {
    final key = _storageKey(sessionId, aiMsgIndex);
    await StorageService.setString(key, userQuery);
    print('[ChatProvider] Persisted spatial key=$key query="$userQuery"');
  }

  /// Rebuilds _spatialResults for all AI messages in [session] that have a
  /// stored query.  Maps result to the message's actual ID (backend ID).
  void _rebuildSpatialResultsForSession(ChatSession session) {
    if (session.id.isEmpty) return;

    // Collect AI messages in order
    final aiMessages =
    session.messages.where((m) => m.isAI).toList();

    for (int i = 0; i < aiMessages.length; i++) {
      final msg = aiMessages[i];
      if (_spatialResults.containsKey(msg.id)) continue; // already loaded

      final storedQuery =
      StorageService.getString(_storageKey(session.id, i));
      if (storedQuery == null || storedQuery.isEmpty) continue;

      try {
        final result = _spatialService.buildSpatialAnalysis(
          query: storedQuery,
          response: _DummyChatResponse(),
          analysisData: {
            'top_provinces': kProvinceCoordinates.keys
                .map((k) => {'provinsi': k, 'total': 0})
                .toList()
          },
        );

        if (result.hasLocations) {
          _spatialResults[msg.id] = result;
          print('[ChatProvider] Restored spatial msgId=${msg.id} '
              'aiIdx=$i query="$storedQuery"');
        }
      } catch (e) {
        print('[ChatProvider] Restore failed msgId=${msg.id}: $e');
      }
    }
  }

  /// Removes all stored spatial queries for a given session (up to 200 entries).
  Future<void> _clearPersistedSpatialForSession(String sessionId) async {
    for (int i = 0; i < 200; i++) {
      final key = _storageKey(sessionId, i);
      final val = StorageService.getString(key);
      if (val == null) break;
      await StorageService.remove(key);
    }
  }

  // ─── Edit & Resend ────────────────────────────────────────────────────────

  /// Edit a user message: remove it and all subsequent messages, then resend
  /// with the new content.
  void editAndResend(String messageId, String newContent) {
    if (_currentSession == null || newContent.trim().isEmpty) return;

    final messages = _currentSession!.messages;
    final editIndex = messages.indexWhere((m) => m.id == messageId);
    if (editIndex < 0) return;

    // Remove the edited message and everything after it
    final trimmedMessages = messages.sublist(0, editIndex);

    // Also remove spatial results for removed AI messages
    for (int i = editIndex; i < messages.length; i++) {
      _spatialResults.remove(messages[i].id);
    }

    _currentSession = _currentSession!.copyWith(
      messages: trimmedMessages,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Now send the edited content as a new message
    sendMessage(newContent);
  }

  // ─── Send Message ─────────────────────────────────────────────────────────
  Future<ChatResponse?> sendMessage(String message) async {
    if (message.trim().isEmpty || _isSending) return null;

    _isSending = true;
    _error = null;
    notifyListeners();

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _currentSession?.id ?? '',
      sender: 'user',
      content: message.trim(),
      timestamp: DateTime.now(),
    );

    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        messages: [..._currentSession!.messages, userMessage],
        updatedAt: DateTime.now(),
      );
    } else {
      _currentSession = ChatSession(
        id: '',
        userId: _authProvider.user?.userId,
        title: _generateTitle(message),
        messages: [userMessage],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    notifyListeners();

    try {
      if (!isBackendAvailable) {
        await checkBackendStatus();
        if (!isBackendAvailable)
          throw Exception('Server sedang tidak tersedia');
      }

      final response = await _apiService.sendMessage(
        message,
        sessionId:
        _currentSession!.id.isNotEmpty ? _currentSession!.id : null,
      );

      // Use a local id for immediate display (before backend assigns its own)
      final localAiId =
          '${response.sessionId}_ai_${DateTime.now().millisecondsSinceEpoch}';

      final aiMessage = ChatMessage(
        id: localAiId,
        sessionId: response.sessionId,
        sender: 'ai',
        content: response.message,
        timestamp: DateTime.now(),
        visualizations: response.visualizations,
        insights: response.insights,
        policies: response.policies,
      );

      // Commit updated session (needed to count AI message position below)
      _currentSession = _currentSession!.copyWith(
        id: response.sessionId,
        title: _currentSession!.title.isEmpty ||
            _currentSession!.title == 'Analisis Sensus Baru'
            ? _generateTitle(message)
            : _currentSession!.title,
        messages: [..._currentSession!.messages, aiMessage],
        updatedAt: DateTime.now(),
      );

      // ── Spatial Analysis ──────────────────────────────────────────────────
      if (SpatialAnalysisService.isSpatialQuery(message)) {
        final spatialResult = await _buildSpatialFromResponse(
          message: message,
          response: response,
        );

        if (spatialResult != null && spatialResult.hasLocations) {
          // Map to local AI id for immediate display
          _spatialResults[localAiId] = spatialResult;

          // Determine 0-based position among AI messages for persistence
          final aiMsgIndex = _currentSession!.messages
              .where((m) => m.isAI)
              .toList()
              .indexWhere((m) => m.id == localAiId);

          if (aiMsgIndex >= 0) {
            await _persistSpatialQuery(
                response.sessionId, aiMsgIndex, message.trim());
          }

          print('[ChatProvider] Spatial stored localId=$localAiId '
              'aiIdx=$aiMsgIndex locations=${spatialResult.locations.length}');
        }
      }

      _updateSessionsList();
      await checkBackendStatus();

      _isSending = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('[ChatProvider] sendMessage error: $e');
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentSession?.id ?? '',
        sender: 'ai',
        content:
        'Maaf, terjadi kesalahan: ${_parseError(e)}. Silakan coba lagi.',
        timestamp: DateTime.now(),
      );
      _currentSession = _currentSession!.copyWith(
        messages: [..._currentSession!.messages, errorMessage],
      );
      _error = _parseError(e);
      _isSending = false;
      notifyListeners();
      return null;
    }
  }

  // ─── Build spatial analysis from API response ─────────────────────────────
  Future<SpatialAnalysisResult?> _buildSpatialFromResponse({
    required String message,
    required ChatResponse response,
  }) async {
    try {
      Map<String, dynamic> analysisData = {};

      if (response.visualizations != null &&
          response.visualizations!.isNotEmpty) {
        for (final viz in response.visualizations!) {
          final cfg = viz.config;
          final xAxis = cfg['xAxis'];
          final series = cfg['series'];
          if (xAxis is Map && series is List && series.isNotEmpty) {
            final categories =
                (xAxis['data'] as List?)?.cast<String>() ?? <String>[];
            final seriesData = series[0]['data'];
            if (categories.isNotEmpty && seriesData is List) {
              final topProvinces = <Map<String, dynamic>>[];
              for (int i = 0; i < categories.length; i++) {
                topProvinces.add({
                  'provinsi': categories[i],
                  'total': seriesData.length > i
                      ? (seriesData[i] is num
                      ? (seriesData[i] as num).toInt()
                      : 0)
                      : 0,
                  'percentage': 0,
                });
              }
              analysisData['top_provinces'] = topProvinces;
              break;
            }
            final pieData = series[0]['data'];
            if (pieData is List &&
                pieData.isNotEmpty &&
                pieData[0] is Map) {
              final topProvinces = <Map<String, dynamic>>[];
              for (final item in pieData) {
                if (item is Map) {
                  topProvinces.add({
                    'provinsi': item['name']?.toString() ?? '',
                    'total': (item['value'] is num)
                        ? (item['value'] as num).toInt()
                        : 0,
                  });
                }
              }
              analysisData['top_provinces'] = topProvinces;
              break;
            }
          }
        }
      }

      if (analysisData.isEmpty) {
        analysisData['top_provinces'] = kProvinceCoordinates.keys
            .map((k) => {'provinsi': k, 'total': 0})
            .toList();
      }

      return _spatialService.buildSpatialAnalysis(
        query: message,
        response: response,
        analysisData: analysisData,
      );
    } catch (e) {
      print('[ChatProvider] Spatial build error: $e');
      return null;
    }
  }

  // ─── Session management ───────────────────────────────────────────────────
  void _updateSessionsList() {
    if (_currentSession == null) return;
    final idx = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (idx >= 0) {
      _sessions[idx] = _currentSession!;
    } else if (_currentSession!.id.isNotEmpty) {
      _sessions.insert(0, _currentSession!);
    }
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  String _generateTitle(String message) {
    final words = message.split(' ').take(6).join(' ');
    return words.length > 50 ? '${words.substring(0, 47)}...' : words;
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      await _apiService.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_currentSession?.id == sessionId) createNewChat();
      await _clearPersistedSpatialForSession(sessionId);
      _spatialResults
          .removeWhere((k, _) => k.startsWith('${sessionId}_ai_'));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus sesi';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSessions(List<String> sessionIds) async {
    try {
      await _apiService.deleteSessions(sessionIds);
      _sessions.removeWhere((s) => sessionIds.contains(s.id));
      if (_currentSession != null &&
          sessionIds.contains(_currentSession!.id)) {
        createNewChat();
      }
      for (final sid in sessionIds) {
        await _clearPersistedSpatialForSession(sid);
        _spatialResults.removeWhere((k, _) => k.startsWith('${sid}_ai_'));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus sesi';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllSessions() async {
    try {
      await _apiService.deleteAllSessions();
      for (final s in _sessions) {
        await _clearPersistedSpatialForSession(s.id);
      }
      _sessions.clear();
      _spatialResults.clear();
      createNewChat();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus semua sesi';
      notifyListeners();
      return false;
    }
  }

  Map<String, dynamic> exportCurrentChat() {
    if (_currentSession == null) return {};
    return {
      'title': _currentSession!.title,
      'created': _currentSession!.createdAt.toIso8601String(),
      'messages': _currentSession!.messages
          .map((m) => <String, dynamic>{
        'sender': m.sender,
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
        'hasSpatial': _spatialResults.containsKey(m.id),
      })
          .toList(),
    };
  }

  Map<String, dynamic> exportAllChats() {
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'totalSessions': _sessions.length,
      'sessions': _sessions
          .map((s) => <String, dynamic>{
        'id': s.id,
        'title': s.title,
        'created': s.createdAt.toIso8601String(),
        'messageCount': s.messages.length,
      })
          .toList(),
    };
  }

  String getReportUrl(String format) {
    if (_currentSession == null || _currentSession!.id.isEmpty) return '';
    return _apiService.getReportUrl(_currentSession!.id, format);
  }

  String getReportPreviewUrl() {
    if (_currentSession == null || _currentSession!.id.isEmpty) return '';
    return _apiService.getReportPreviewUrl(_currentSession!.id);
  }

  int get totalMessages =>
      _sessions.fold(0, (sum, s) => sum + s.realMessageCount);

  int get totalInsights {
    int count = 0;
    for (final session in _sessions) {
      for (final message in session.messages) {
        if (message.insights != null) count += message.insights!.length;
      }
    }
    return count;
  }

  int get totalVisualizations {
    int count = 0;
    for (final session in _sessions) {
      for (final message in session.messages) {
        if (message.visualizations != null) {
          count += message.visualizations!.length;
        }
      }
    }
    return count;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }

  String _parseError(dynamic error) {
    final s = error.toString().toLowerCase();
    if (s.contains('401') || s.contains('403')) {
      return 'Sesi telah berakhir, silakan login kembali';
    }
    if (s.contains('404')) return 'Sesi tidak ditemukan';
    if (s.contains('500') || s.contains('503')) {
      return 'Server sedang mengalami masalah';
    }
    if (s.contains('network') || s.contains('connection')) {
      return 'Tidak dapat terhubung ke server';
    }
    if (s.contains('timeout')) return 'Koneksi timeout, coba lagi';
    return 'Terjadi kesalahan, silakan coba lagi';
  }
}

// ─── Minimal stub used when restoring spatial results from storage ────────────
class _DummyChatResponse implements ChatResponse {
  @override
  String get message => '';
  @override
  String get sessionId => '';
  @override
  List<VisualizationConfig>? get visualizations => null;
  @override
  List<String>? get insights => null;
  @override
  List<PolicyRecommendation>? get policies => null;
  @override
  int get supportingDataCount => 0;
}