import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'dart:convert';

/// ChatProvider - manages chat sessions and messages
/// Matches backend server.py chat endpoints
class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;

  ChatSession? _currentSession;
  List<ChatSession> _sessions = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  HealthStatus? _healthStatus;
  bool _initialized = false;

  // Constructor
  ChatProvider(this._apiService, this._authProvider) {
    // Listen to auth changes - THIS IS THE KEY FIX
    _authProvider.addListener(_onAuthChanged);
    _init();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Called when auth state changes (login/logout)
  void _onAuthChanged() {
    print('[ChatProvider] Auth state changed: isAuthenticated=${_authProvider.isAuthenticated}');
    if (_authProvider.isAuthenticated) {
      // User just logged in - reload sessions
      print('[ChatProvider] User logged in, reloading sessions...');
      loadSessions();
    } else {
      // User logged out - clear sessions
      print('[ChatProvider] User logged out, clearing sessions...');
      _sessions = [];
      _currentSession = null;
      notifyListeners();
    }
  }

  // Getters
  ChatSession? get currentSession => _currentSession;
  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  HealthStatus? get healthStatus => _healthStatus;

  bool get isBackendAvailable => _healthStatus?.isHealthy ?? false;
  String get scrapingStatus => _healthStatus?.scrapingStatus ?? 'idle';

  /// Initialize chat state
  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    await checkBackendStatus();

    // Only load sessions if already authenticated
    if (_authProvider.isAuthenticated) {
      await loadSessions();
    }
  }

  /// Force refresh sessions - call this after login
  Future<void> refreshAfterLogin() async {
    print('[ChatProvider] Refreshing after login...');
    await checkBackendStatus();
    await loadSessions();
  }

  /// Check backend health status
  /// Backend: GET /api/health
  Future<void> checkBackendStatus() async {
    try {
      final health = await _apiService.getHealth();
      _healthStatus = HealthStatus.fromJson(health);
      print('[ChatProvider] Backend status: ${_healthStatus?.status}');
    } catch (e) {
      print('[ChatProvider] Health check error: $e');
      _healthStatus = null;
    }
    notifyListeners();
  }

  /// Load user's chat sessions
  /// Backend: GET /api/sessions
  Future<void> loadSessions() async {
    // Only load if authenticated
    if (!_authProvider.isAuthenticated) {
      print('[ChatProvider] Not authenticated, skipping loadSessions');
      _sessions = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print('[ChatProvider] Loading sessions for user: ${_authProvider.user?.email}');
      _sessions = await _apiService.getSessions();
      // Sort by updated_at descending (newest first)
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _error = null;
      print('[ChatProvider] Loaded ${_sessions.length} sessions');
    } catch (e) {
      print('[ChatProvider] Load sessions error: $e');
      _error = 'Gagal memuat sesi chat';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create new chat session (local only until first message)
  void createNewChat() {
    _currentSession = ChatSession(
      id: '', // Will be assigned by backend
      userId: _authProvider.user?.userId,
      title: 'Analisis Sensus Baru',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    print('[ChatProvider] Created new local chat session');
    notifyListeners();
  }

  /// Switch to existing session
  /// Backend: GET /api/sessions/{session_id}
  Future<void> switchToSession(String sessionId) async {
    if (_currentSession?.id == sessionId) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Try to find in local cache first
      final cachedSession = _sessions.firstWhere(
            (s) => s.id == sessionId,
        orElse: () => ChatSession(
          id: sessionId,
          title: '',
          messages: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Show cached data immediately
      if (cachedSession.messages.isNotEmpty) {
        _currentSession = cachedSession;
        notifyListeners();
      }

      // Fetch fresh data from backend
      final session = await _apiService.getSession(sessionId);
      _currentSession = session;

      // Update cache
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index >= 0) {
        _sessions[index] = session;
      }

      _error = null;
      print('[ChatProvider] Switched to session $sessionId with ${session.messages.length} messages');
    } catch (e) {
      print('[ChatProvider] Switch session error: $e');
      _error = 'Gagal memuat sesi';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Send message to AI
  /// Backend: POST /api/chat
  Future<ChatResponse?> sendMessage(String message) async {
    if (message.trim().isEmpty || _isSending) return null;

    _isSending = true;
    _error = null;
    notifyListeners();

    // Create user message locally
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _currentSession?.id ?? '',
      sender: 'user',
      content: message.trim(),
      timestamp: DateTime.now(),
    );

    // Add to current session
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        messages: [..._currentSession!.messages, userMessage],
        updatedAt: DateTime.now(),
      );
    } else {
      // Create new session
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
      // Check backend availability
      if (!isBackendAvailable) {
        await checkBackendStatus();
        if (!isBackendAvailable) {
          throw Exception('Server sedang tidak tersedia');
        }
      }

      // Send to backend
      final response = await _apiService.sendMessage(
        message,
        sessionId: _currentSession!.id.isNotEmpty ? _currentSession!.id : null,
      );

      // Create AI response message
      final aiMessage = ChatMessage(
        id: '${response.sessionId}_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: response.sessionId,
        sender: 'ai',
        content: response.message,
        timestamp: DateTime.now(),
        visualizations: response.visualizations,
        insights: response.insights,
        policies: response.policies,
      );

      // Update current session with backend session ID
      _currentSession = _currentSession!.copyWith(
        id: response.sessionId,
        title: _currentSession!.title.isEmpty || _currentSession!.title == 'Analisis Sensus Baru'
            ? _generateTitle(message)
            : _currentSession!.title,
        messages: [..._currentSession!.messages, aiMessage],
        updatedAt: DateTime.now(),
      );

      // Update sessions list
      _updateSessionsList();

      // Refresh health status
      await checkBackendStatus();

      print('[ChatProvider] Message sent, session: ${response.sessionId}');
      print('[ChatProvider] Response has ${response.visualizations?.length ?? 0} visualizations');
      print('[ChatProvider] Response has ${response.insights?.length ?? 0} insights');
      print('[ChatProvider] Response has ${response.policies?.length ?? 0} policies');

      _isSending = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('[ChatProvider] Send message error: $e');

      // Add error message
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: _currentSession?.id ?? '',
        sender: 'ai',
        content: 'Maaf, terjadi kesalahan: ${_parseError(e)}. Silakan coba lagi.',
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

  /// Update sessions list with current session
  void _updateSessionsList() {
    if (_currentSession == null) return;

    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (index >= 0) {
      _sessions[index] = _currentSession!;
    } else if (_currentSession!.id.isNotEmpty) {
      _sessions.insert(0, _currentSession!);
    }

    // Sort by updated_at
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Generate title from message
  String _generateTitle(String message) {
    final words = message.split(' ').take(6).join(' ');
    return words.length > 50 ? '${words.substring(0, 47)}...' : words;
  }

  /// Delete single session
  /// Backend: DELETE /api/sessions/{session_id}
  Future<bool> deleteSession(String sessionId) async {
    try {
      await _apiService.deleteSession(sessionId);
      _sessions.removeWhere((s) => s.id == sessionId);

      if (_currentSession?.id == sessionId) {
        createNewChat();
      }

      print('[ChatProvider] Deleted session $sessionId');
      notifyListeners();
      return true;
    } catch (e) {
      print('[ChatProvider] Delete session error: $e');
      _error = 'Gagal menghapus sesi';
      notifyListeners();
      return false;
    }
  }

  /// Delete multiple sessions
  /// Backend: DELETE /api/sessions/batch
  Future<bool> deleteSessions(List<String> sessionIds) async {
    try {
      await _apiService.deleteSessions(sessionIds);
      _sessions.removeWhere((s) => sessionIds.contains(s.id));

      if (_currentSession != null && sessionIds.contains(_currentSession!.id)) {
        createNewChat();
      }

      print('[ChatProvider] Deleted ${sessionIds.length} sessions');
      notifyListeners();
      return true;
    } catch (e) {
      print('[ChatProvider] Delete sessions error: $e');
      _error = 'Gagal menghapus sesi';
      notifyListeners();
      return false;
    }
  }

  /// Delete all sessions
  /// Backend: DELETE /api/sessions/all
  Future<bool> deleteAllSessions() async {
    try {
      await _apiService.deleteAllSessions();
      _sessions.clear();
      createNewChat();

      print('[ChatProvider] Deleted all sessions');
      notifyListeners();
      return true;
    } catch (e) {
      print('[ChatProvider] Delete all sessions error: $e');
      _error = 'Gagal menghapus semua sesi';
      notifyListeners();
      return false;
    }
  }

  /// Export current chat data
  Map<String, dynamic> exportCurrentChat() {
    if (_currentSession == null) return {};

    return {
      'title': _currentSession!.title,
      'created': _currentSession!.createdAt.toIso8601String(),
      'messages': _currentSession!.messages.map((m) {
        return <String, dynamic>{
          'sender': m.sender,
          'content': m.content,
          'timestamp': m.timestamp.toIso8601String(),
          'hasVisualizations': m.hasVisualizations,
          'hasInsights': m.hasInsights,
          'hasPolicies': m.hasPolicies,
        };
      }).toList(),
    };
  }

  /// Export all chats data
  Map<String, dynamic> exportAllChats() {
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'totalSessions': _sessions.length,
      'sessions': _sessions.map((s) {
        return <String, dynamic>{
          'id': s.id,
          'title': s.title,
          'created': s.createdAt.toIso8601String(),
          'messageCount': s.messages.length,
        };
      }).toList(),
    };
  }

  /// Get report URL for a session
  /// Backend: GET /api/report/{session_id}/{format}
  String getReportUrl(String format) {
    if (_currentSession == null || _currentSession!.id.isEmpty) return '';
    return _apiService.getReportUrl(_currentSession!.id, format);
  }

  /// Get report preview URL
  /// Backend: GET /api/report/{session_id}/preview
  String getReportPreviewUrl() {
    if (_currentSession == null || _currentSession!.id.isEmpty) return '';
    return _apiService.getReportPreviewUrl(_currentSession!.id);
  }

  /// Total messages across all sessions
  int get totalMessages {
    return _sessions.fold(0, (sum, s) => sum + s.realMessageCount);
  }

  /// Total insights across all sessions
  int get totalInsights {
    int count = 0;
    for (final session in _sessions) {
      for (final message in session.messages) {
        if (message.insights != null) {
          count += message.insights!.length;
        }
      }
    }
    return count;
  }

  /// Total visualizations across all sessions
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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear current session
  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }

  /// Parse error message
  String _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('401') || errorStr.contains('403')) {
      return 'Sesi telah berakhir, silakan login kembali';
    } else if (errorStr.contains('404')) {
      return 'Sesi tidak ditemukan';
    } else if (errorStr.contains('500') || errorStr.contains('503')) {
      return 'Server sedang mengalami masalah';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Tidak dapat terhubung ke server';
    } else if (errorStr.contains('timeout')) {
      return 'Koneksi timeout, coba lagi';
    }

    return 'Terjadi kesalahan, silakan coba lagi';
  }
}