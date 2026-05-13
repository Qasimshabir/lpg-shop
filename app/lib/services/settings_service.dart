import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for managing application settings including Base URL configuration
class SettingsService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _defaultBaseUrl = 'https://server-lpg-shop.vercel.app/api';
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';
  static const String _notificationsKey = 'notifications_enabled';
  
  static SharedPreferences? _prefs;

  /// Initialize the settings service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the configured Base URL or return default
  static String getBaseUrl() {
    if (_prefs == null) {
      print('⚠️ SettingsService: SharedPreferences not initialized, returning default');
      return _defaultBaseUrl;
    }
    final url = _prefs!.getString(_baseUrlKey) ?? _defaultBaseUrl;
    print('✅ SettingsService: Getting Base URL: $url');
    return url;
  }

  /// Save a new Base URL
  static Future<bool> setBaseUrl(String url) async {
    if (_prefs == null) {
      await init();
    }
    print('💾 SettingsService: Saving Base URL: $url');
    final result = await _prefs!.setString(_baseUrlKey, url);
    print('✅ SettingsService: Save result: $result');
    return result;
  }

  /// Check if a custom Base URL has been configured
  static bool hasCustomBaseUrl() {
    if (_prefs == null) {
      print('⚠️ SettingsService: SharedPreferences not initialized for hasCustomBaseUrl check');
      return false;
    }
    final hasCustom = _prefs!.containsKey(_baseUrlKey);
    print('🔍 SettingsService: Has custom URL: $hasCustom');
    return hasCustom;
  }

  /// Reset Base URL to default
  static Future<bool> resetBaseUrl() async {
    if (_prefs == null) {
      await init();
    }
    return await _prefs!.remove(_baseUrlKey);
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      // Must have a scheme (http or https)
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      
      // Must have a host
      if (!uri.hasAuthority || uri.host.isEmpty) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Normalize URL by removing trailing slashes and ensuring /api suffix
  static String normalizeUrl(String url) {
    // Remove trailing slashes
    url = url.trimRight();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    // Ensure it ends with /api
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    
    return url;
  }

  // Language Settings
  static String getLanguage() {
    if (_prefs == null) return 'English';
    return _prefs!.getString(_languageKey) ?? 'English';
  }

  static Future<bool> setLanguage(String language) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_languageKey, language);
  }

  // Theme Settings
  static String getTheme() {
    if (_prefs == null) return 'Light';
    return _prefs!.getString(_themeKey) ?? 'Light';
  }

  static Future<bool> setTheme(String theme) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(_themeKey, theme);
  }

  // Notification Settings
  static bool getNotificationsEnabled() {
    if (_prefs == null) return true;
    return _prefs!.getBool(_notificationsKey) ?? true;
  }

  static Future<bool> setNotificationsEnabled(bool enabled) async {
    if (_prefs == null) await init();
    return await _prefs!.setBool(_notificationsKey, enabled);
  }

  // Cache Management
  static Future<bool> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        await cacheDir.create();
      }
      return true;
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (!cacheDir.existsSync()) return 0;
      
      int totalSize = 0;
      await for (var entity in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  // Data Export/Import
  static Future<String> exportSettings() async {
    if (_prefs == null) await init();
    
    final settings = {
      'base_url': getBaseUrl(),
      'language': getLanguage(),
      'theme': getTheme(),
      'notifications_enabled': getNotificationsEnabled(),
      'export_date': DateTime.now().toIso8601String(),
    };
    
    return jsonEncode(settings);
  }

  static Future<bool> importSettings(String jsonData) async {
    try {
      if (_prefs == null) await init();
      
      final settings = jsonDecode(jsonData) as Map<String, dynamic>;
      
      if (settings['base_url'] != null) {
        await setBaseUrl(settings['base_url']);
      }
      if (settings['language'] != null) {
        await setLanguage(settings['language']);
      }
      if (settings['theme'] != null) {
        await setTheme(settings['theme']);
      }
      if (settings['notifications_enabled'] != null) {
        await setNotificationsEnabled(settings['notifications_enabled']);
      }
      
      return true;
    } catch (e) {
      print('Error importing settings: $e');
      return false;
    }
  }

  // Reset all settings
  static Future<bool> resetAllSettings() async {
    if (_prefs == null) await init();
    return await _prefs!.clear();
  }
}
