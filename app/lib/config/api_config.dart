import 'package:flutter/foundation.dart';

class ApiConfig {
  // Automatically use localhost for web, and your network IP for mobile devices
  static String get baseUrl {
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
}
