import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

class ApiConfig {
  // Get Base URL from settings service, with fallback to platform-specific defaults
  static String get baseUrl {
    final customUrl = SettingsService.getBaseUrl();
    
    if (kDebugMode) {
      debugPrint('=== API CONFIG DEBUG ===');
      debugPrint('Custom URL from settings: $customUrl');
      debugPrint('Has custom URL: ${SettingsService.hasCustomBaseUrl()}');
    }
    
    // Always return what SettingsService gives us (it has its own defaults)
    return customUrl;
  }

  // LPG routes are directly under /api, not /api/lpg
  static String get lpgBaseUrl => baseUrl;
  
  // Get the configured or default base URL
  static String getConfiguredBaseUrl() {
    return SettingsService.getBaseUrl();
  }
  
  // Check if using custom URL
  static bool get isUsingCustomUrl => SettingsService.hasCustomBaseUrl();
}
