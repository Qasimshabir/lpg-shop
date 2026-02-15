import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

class ApiConfig {
  // Get Base URL from settings service, with fallback to platform-specific defaults
  static String get baseUrl {
    // Check if a custom URL has been configured
    if (SettingsService.hasCustomBaseUrl()) {
      return SettingsService.getBaseUrl();
    }
    
    // Fallback to platform-specific defaults
    if (kIsWeb) {
      // For web (Chrome), use localhost
      return 'http://localhost:5000/api';
    } else {
      // For mobile devices, use your computer's IP address
      // Replace this with your actual IP if different
      return 'http://10.141.196.72:5000/api';
    }
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
