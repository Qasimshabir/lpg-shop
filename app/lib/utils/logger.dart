import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _prefix = '[LPG App]';
  
  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix [DEBUG] $message');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }
  
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix [INFO] $message');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }
  
  static void warning(String message, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix [WARNING] $message');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix [ERROR] $message');
      if (error != null) {
        print('  Error: $error');
      }
      if (stackTrace != null) {
        print('  Stack trace: $stackTrace');
      }
    }
  }
  
  static void apiRequest(String method, String url, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix [API REQUEST] $method $url');
      if (data != null) {
        print('  Body: $data');
      }
    }
  }
  
  static void apiResponse(String method, String url, int statusCode, [dynamic data]) {
    if (kDebugMode) {
      print('$_prefix [API RESPONSE] $method $url - Status: $statusCode');
      if (data != null) {
        print('  Response: $data');
      }
    }
  }
  
  static void apiError(String method, String url, dynamic error) {
    if (kDebugMode) {
      print('$_prefix [API ERROR] $method $url');
      print('  Error: $error');
    }
  }
}
