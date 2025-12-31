import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// User model matching backend auth_models.py User
class AppUser {
  final String userId;
  final String email;
  final String name;
  final String? picture;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AppUser({
    required this.userId,
    required this.email,
    required this.name,
    this.picture,
    this.createdAt,
    this.lastLogin,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'] ?? json['id'] ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'name': name,
      'picture': picture,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}

/// AuthProvider - manages authentication state
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  AppUser? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  AuthProvider(this._apiService) {
    _init();
  }

  // Getters
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  /// Initialize auth state - check if user has valid session
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getSecure('session_token');

      if (token != null) {
        // Verify token with backend
        final response = await _apiService.getMe();

        if (response.success && response.user != null) {
          _user = AppUser(
            userId: response.user!.id,
            email: response.user!.email,
            name: response.user!.name,
            picture: response.user!.picture,
            createdAt: response.user!.createdAt,
            lastLogin: response.user!.lastLogin,
          );
          _isAuthenticated = true;
          print('[AuthProvider] User authenticated: ${_user!.email}');
        } else {
          // Token invalid, clear storage
          await StorageService.instance.clearAll();
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      print('[AuthProvider] Init error: $e');
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with email and password
  /// Backend: POST /api/auth/login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      if (response.success && response.user != null) {
        _user = AppUser(
          userId: response.user!.id,
          email: response.user!.email,
          name: response.user!.name,
          picture: response.user!.picture,
          createdAt: response.user!.createdAt,
          lastLogin: response.user!.lastLogin,
        );
        _isAuthenticated = true;

        // Save user data locally
        await StorageService.set('user_email', _user!.email);
        await StorageService.set('user_name', _user!.name);
        await StorageService.set('user_id', _user!.userId);

        print('[AuthProvider] Login success: ${_user!.email}');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Login error: $e');
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  /// Backend: POST /api/auth/register
  /// Parameters: name, email, password (in this order)
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Debug log to verify parameters
      print('[AuthProvider] Registering user:');
      print('[AuthProvider] - Name: $name');
      print('[AuthProvider] - Email: $email');
      print('[AuthProvider] - Password length: ${password.length}');

      // Call API with correct order: email, password, name (as expected by api_service)
      final response = await _apiService.register(email, password, name);

      if (response.success && response.user != null) {
        _user = AppUser(
          userId: response.user!.id,
          email: response.user!.email,
          name: response.user!.name,
          picture: response.user!.picture,
          createdAt: response.user!.createdAt,
          lastLogin: response.user!.lastLogin,
        );
        _isAuthenticated = true;

        // Save user data locally
        await StorageService.set('user_email', _user!.email);
        await StorageService.set('user_name', _user!.name);
        await StorageService.set('user_id', _user!.userId);

        print('[AuthProvider] Registration success: ${_user!.email}');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Registrasi gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Register error: $e');
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get Google OAuth login URL
  /// Opens browser/webview to Google consent screen
  String getGoogleLoginUrl() {
    return _apiService.getGoogleLoginUrl();
  }

  /// Login with Google ID Token (for native Google Sign In)
  /// Backend: POST /api/auth/google/mobile
  Future<bool> loginWithGoogle({
    required String idToken,
    required String email,
    required String name,
    String? picture,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[AuthProvider] Google login with ID token');
      print('[AuthProvider] - Email: $email');
      print('[AuthProvider] - Name: $name');

      // Send ID token to backend for verification
      final response = await _apiService.loginWithGoogleToken(
        idToken: idToken,
        email: email,
        name: name,
        picture: picture,
      );

      if (response.success && response.user != null) {
        _user = AppUser(
          userId: response.user!.id,
          email: response.user!.email,
          name: response.user!.name,
          picture: response.user!.picture,
          createdAt: response.user!.createdAt,
          lastLogin: response.user!.lastLogin,
        );
        _isAuthenticated = true;

        // Save user data locally
        await StorageService.set('user_email', _user!.email);
        await StorageService.set('user_name', _user!.name);
        await StorageService.set('user_id', _user!.userId);

        print('[AuthProvider] Google login success: ${_user!.email}');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Google login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('[AuthProvider] Google login error: $e');
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Handle OAuth callback - called after Google redirects back
  /// The backend sets session_token cookie automatically
  Future<bool> handleOAuthCallback({
    required String sessionToken,
    required String userId,
    required String email,
    required String name,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Save session token
      await StorageService.setSecure('session_token', sessionToken);

      // Create user object
      _user = AppUser(
        userId: userId,
        email: email,
        name: name,
      );
      _isAuthenticated = true;

      // Save user data locally
      await StorageService.set('user_email', email);
      await StorageService.set('user_name', name);
      await StorageService.set('user_id', userId);

      print('[AuthProvider] OAuth callback success: $email');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[AuthProvider] OAuth callback error: $e');
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  /// Backend: POST /api/auth/logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      print('[AuthProvider] Logout API error: $e');
      // Continue with local logout even if API fails
    }

    // Clear local state
    _user = null;
    _isAuthenticated = false;
    _error = null;

    // Clear all stored data
    await StorageService.instance.clearAll();

    print('[AuthProvider] Logout complete');

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;

    try {
      final response = await _apiService.getMe();

      if (response.success && response.user != null) {
        _user = AppUser(
          userId: response.user!.id,
          email: response.user!.email,
          name: response.user!.name,
          picture: response.user!.picture,
          createdAt: response.user!.createdAt,
          lastLogin: response.user!.lastLogin,
        );
        notifyListeners();
      }
    } catch (e) {
      print('[AuthProvider] Refresh user error: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Parse error message from exception
  String _parseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('422')) {
      return 'Data tidak valid. Pastikan email belum terdaftar dan password minimal 6 karakter.';
    } else if (errorStr.contains('401')) {
      return 'Email atau password salah';
    } else if (errorStr.contains('400')) {
      if (errorStr.contains('already exists') || errorStr.contains('already registered')) {
        return 'Email sudah terdaftar';
      }
      return 'Data tidak valid';
    } else if (errorStr.contains('409')) {
      return 'Email sudah terdaftar';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Tidak dapat terhubung ke server';
    } else if (errorStr.contains('timeout')) {
      return 'Koneksi timeout, coba lagi';
    }

    return 'Terjadi kesalahan, silakan coba lagi';
  }
}