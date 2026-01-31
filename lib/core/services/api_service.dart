import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../models/chat_models.dart';

/// API Response models matching backend auth_models.py
class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? picture;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.picture,
    this.createdAt,
    this.lastLogin,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['user_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      picture: json['picture'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
    );
  }
}

class AuthResponse {
  final bool success;
  final String? sessionToken;
  final AuthUser? user;
  final String? error;

  AuthResponse({
    required this.success,
    this.sessionToken,
    this.user,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      sessionToken: json['session_token'],
      user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
      error: json['error'] ?? json['message'],
    );
  }
}

/// ApiService - handles all HTTP requests to backend
class ApiService {
  static const String baseUrl = 'https://smart-se26-agentic-ai-production.up.railway.app/api';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add session token to all requests
        final token = await StorageService.getSecure('session_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('[API] ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('[API] Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('[API] Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  // ============================================
  // HEALTH CHECK
  // ============================================

  /// Health check - basic
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health', options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      return response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  /// Health check - detailed (used by ChatProvider)
  /// Backend: GET /api/health
  Future<Map<String, dynamic>> getHealth() async {
    final response = await _dio.get('/health');
    return response.data;
  }

  // ============================================
  // AUTHENTICATION - matches /api/auth/*
  // Backend: auth_routes.py
  // ============================================

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final authResponse = AuthResponse.fromJson(response.data);

    // Save session token if login successful
    if (authResponse.success && authResponse.sessionToken != null) {
      await StorageService.setSecure('session_token', authResponse.sessionToken!);
    }

    return authResponse;
  }

  Future<AuthResponse> register(String email, String password, String name) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });

    final authResponse = AuthResponse.fromJson(response.data);

    // Save session token if registration successful
    if (authResponse.success && authResponse.sessionToken != null) {
      await StorageService.setSecure('session_token', authResponse.sessionToken!);
    }

    return authResponse;
  }

  Future<AuthResponse> getMe() async {
    final response = await _dio.get('/auth/me');
    return AuthResponse.fromJson(response.data);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      print('[API] Logout error: $e');
    } finally {
      // Always clear local storage
      await StorageService.instance.clearAll();
    }
  }

  // Google OAuth URL - for WebView/Browser (Web flow)
  String getGoogleLoginUrl() {
    return '$baseUrl/auth/google/login';
  }

  /// Login with Google ID Token (Native mobile Google Sign-In)
  /// Backend: POST /api/auth/google/mobile
  Future<AuthResponse> loginWithGoogleToken({
    required String idToken,
    required String email,
    required String name,
    String? picture,
  }) async {
    final response = await _dio.post('/auth/google/mobile', data: {
      'id_token': idToken,
      'email': email,
      'name': name,
      'picture': picture,
    });

    final authResponse = AuthResponse.fromJson(response.data);

    // Save session token if login successful
    if (authResponse.success && authResponse.sessionToken != null) {
      await StorageService.setSecure('session_token', authResponse.sessionToken!);
    }

    return authResponse;
  }

  // Check if Google OAuth is configured
  Future<Map<String, dynamic>> getGoogleOAuthStatus() async {
    try {
      final response = await _dio.get('/auth/google/status');
      return response.data;
    } catch (e) {
      return {'configured': false};
    }
  }

  // ============================================
  // CHAT / SESSIONS - matches /api/*
  // Backend: server.py
  // ============================================

  /// Send a message and get AI response
  /// Backend: POST /api/chat
  Future<ChatResponse> sendMessage(String message, {String? sessionId}) async {
    final response = await _dio.post('/chat', data: {
      'message': message,
      if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
    });
    return ChatResponse.fromJson(response.data);
  }

  /// Get all chat sessions for current user
  /// Backend: GET /api/sessions
  Future<List<ChatSession>> getSessions() async {
    final response = await _dio.get('/sessions');

    print('[API] getSessions response type: ${response.data.runtimeType}');
    print('[API] getSessions response: ${response.data}');

    // Handle both formats:
    // 1. List directly: [session1, session2, ...]
    // 2. Object with sessions key: {"sessions": [...]}
    List<dynamic> sessionsData;

    if (response.data is List) {
      // Backend returns List directly
      sessionsData = response.data;
    } else if (response.data is Map) {
      // Backend returns object with 'sessions' key
      sessionsData = response.data['sessions'] ?? [];
    } else {
      sessionsData = [];
    }

    print('[API] Parsing ${sessionsData.length} sessions...');

    List<ChatSession> sessions = [];
    for (var s in sessionsData) {
      try {
        if (s is Map<String, dynamic>) {
          sessions.add(ChatSession.fromJson(s));
        } else if (s is Map) {
          sessions.add(ChatSession.fromJson(Map<String, dynamic>.from(s)));
        }
      } catch (e) {
        print('[API] Error parsing session: $e');
      }
    }

    print('[API] Successfully parsed ${sessions.length} sessions');
    return sessions;
  }

  /// Get single session with messages
  /// Backend: GET /api/sessions/{session_id}
  Future<ChatSession> getSession(String sessionId) async {
    final response = await _dio.get('/sessions/$sessionId');
    return ChatSession.fromJson(response.data);
  }

  /// Delete single session
  /// Backend: DELETE /api/sessions/{session_id}
  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('/sessions/$sessionId');
  }

  /// Delete multiple sessions (batch)
  /// Backend: DELETE /api/sessions/batch
  Future<void> deleteSessions(List<String> sessionIds) async {
    await _dio.delete('/sessions/batch', data: {
      'session_ids': sessionIds,
    });
  }

  /// Delete all sessions
  /// Backend: DELETE /api/sessions/all
  Future<void> deleteAllSessions() async {
    await _dio.delete('/sessions/all');
  }

  // ============================================
  // REPORTS - matches /api/report/*
  // Backend: server.py
  // ============================================

  /// Get report URL for a session
  /// Backend: GET /api/report/{session_id}/{format}
  String getReportUrl(String sessionId, String format) {
    return '$baseUrl/report/$sessionId/$format';
  }

  /// Get report preview URL
  /// Backend: GET /api/report/{session_id}/preview
  String getReportPreviewUrl(String sessionId) {
    return '$baseUrl/report/$sessionId/preview';
  }

  // ============================================
  // DATA SCRAPING - matches /api/scraper/*
  // Backend: scraper_routes.py
  // ============================================

  /// Trigger data scraping
  /// Backend: POST /api/scraper/scrape
  Future<Map<String, dynamic>> triggerScraping() async {
    final response = await _dio.post('/scraper/scrape');
    return response.data;
  }

  /// Get scraping status
  /// Backend: GET /api/scraper/status
  Future<Map<String, dynamic>> getScrapingStatus() async {
    final response = await _dio.get('/scraper/status');
    return response.data;
  }

  /// Get available data sources
  /// Backend: GET /api/scraper/sources
  Future<List<Map<String, dynamic>>> getDataSources() async {
    final response = await _dio.get('/scraper/sources');
    return List<Map<String, dynamic>>.from(response.data['sources'] ?? []);
  }

  // ============================================
  // ANALYTICS - matches /api/analytics/*
  // ============================================

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/analytics/dashboard');
      return response.data;
    } catch (e) {
      return {};
    }
  }

  /// Get chart data for visualization
  Future<Map<String, dynamic>> getChartData(String chartType) async {
    try {
      final response = await _dio.get('/analytics/charts/$chartType');
      return response.data;
    } catch (e) {
      return {};
    }
  }

  // ============================================
  // USER PROFILE
  // ============================================

  /// Update user profile
  Future<AuthResponse> updateProfile({
    String? name,
    String? picture,
  }) async {
    final response = await _dio.patch('/auth/profile', data: {
      if (name != null) 'name': name,
      if (picture != null) 'picture': picture,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return response.data;
  }

  // ============================================
  // EXPORT
  // ============================================

  /// Export chat as PDF
  Future<List<int>> exportChatPdf(String sessionId) async {
    final response = await _dio.get(
      '/chat/export/$sessionId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  /// Export chat as JSON
  Future<Map<String, dynamic>> exportChatJson(String sessionId) async {
    final response = await _dio.get('/chat/export/$sessionId/json');
    return response.data;
  }
}