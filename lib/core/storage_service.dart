import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  static const String _keyTheme = 'theme_mode';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyLanguage = 'language';
  static const String _keyLastSyncTime = 'last_sync_time';

  Future<bool> setThemeMode(String mode) async {
    return await _prefs?.setString(_keyTheme, mode) ?? false;
  }

  String getThemeMode() {
    return _prefs?.getString(_keyTheme) ?? 'system';
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await _prefs?.setBool(_keyNotifications, enabled) ?? false;
  }

  bool getNotificationsEnabled() {
    return _prefs?.getBool(_keyNotifications) ?? true;
  }

  Future<bool> setLanguage(String languageCode) async {
    return await _prefs?.setString(_keyLanguage, languageCode) ?? false;
  }

  String getLanguage() {
    return _prefs?.getString(_keyLanguage) ?? 'uk';
  }

  Future<bool> setLastSyncTime(DateTime time) async {
    return await _prefs?.setString(_keyLastSyncTime, time.toIso8601String()) ?? false;
  }

  DateTime? getLastSyncTime() {
    final timeString = _prefs?.getString(_keyLastSyncTime);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}
