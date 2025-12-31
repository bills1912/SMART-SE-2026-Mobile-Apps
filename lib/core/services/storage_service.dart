import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;

  StorageService._internal();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Regular Storage Methods
  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // Convenience methods (non-static, for instance access)
  Future<String?> getToken() async {
    return await getSecure('session_token');
  }

  Future<void> saveToken(String token) async {
    await setSecure('session_token', token);
  }

  Future<void> clearAll() async {
    await clear();
    await clearSecure();
  }

  // Alias methods for easier access
  static Future<bool> set(String key, String value) async {
    return await setString(key, value);
  }

  static String? get(String key) {
    return getString(key);
  }

  // JSON Storage Methods
  static Map<String, dynamic>? getJson(String key) {
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await _prefs?.setString(key, json.encode(value)) ?? false;
  }

  static List<dynamic>? getJsonList(String key) {
    final jsonString = _prefs?.getString(key);
    if (jsonString != null) {
      return json.decode(jsonString) as List<dynamic>;
    }
    return null;
  }

  static Future<bool> setJsonList(String key, List<dynamic> value) async {
    return await _prefs?.setString(key, json.encode(value)) ?? false;
  }

  // Secure Storage Methods (for sensitive data like tokens)
  static Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> setSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  // User Cache Management
  static const String _userCacheKey = 'se26_user_cache';
  static const String _authStatusKey = 'se26_auth_status';
  static const String _authTimestampKey = 'se26_auth_timestamp';

  static Future<void> saveUserCache(Map<String, dynamic> user) async {
    await setJson(_userCacheKey, user);
    await setString(_authStatusKey, 'authenticated');
    await setString(_authTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
  }

  static Map<String, dynamic>? getUserCache() {
    return getJson(_userCacheKey);
  }

  static bool isAuthenticated() {
    return getString(_authStatusKey) == 'authenticated';
  }

  static Future<void> clearAuthData() async {
    await remove(_userCacheKey);
    await remove(_authStatusKey);
    await remove(_authTimestampKey);
    await deleteSecure('session_token');
  }
}