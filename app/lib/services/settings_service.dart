import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing application settings including Base URL configuration
class SettingsService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _defaultBaseUrl = 'http://192.168.18.196:5000/api';
  
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
}
