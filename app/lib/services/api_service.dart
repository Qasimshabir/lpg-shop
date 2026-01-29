import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/feedback.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
  
  bool get isNetworkError => statusCode == 0;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isAuthError => statusCode == 401;
}

class ApiService {
  static const String _baseUrl = 'http://10.141.196.72:5000/api';
  static String? _token;

  // Build a public URL for static assets (e.g., /uploads/...)
  static String publicUrl(String path) {
    if (path.isEmpty) return path;
    // Already absolute http/https URL
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    // Data URI
    if (path.startsWith('data:')) return path;
    final uri = Uri.parse(_baseUrl);
    final origin = uri.hasPort && uri.port != 0
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
    if (path.startsWith('/')) return '$origin$path';
    return '$origin/$path';
  }

  // Initialize token from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  // Clear token from storage
  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // Get headers with auth token
  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Handle API responses with improved error handling
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (kDebugMode) {
      debugPrint('=== HANDLE RESPONSE DEBUG ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
    }
    
    try {
      final data = json.decode(response.body);
      if (kDebugMode) {
        debugPrint('Decoded data: $data');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          debugPrint('Success response');
        }
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('Error response');
        }
        String errorMessage = _getErrorMessage(response.statusCode, data);
        if (kDebugMode) {
          debugPrint('Error message: $errorMessage');
        }
        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error decoding response: $e');
      }
      if (e is ApiException) {
        rethrow;
      } else if (e is FormatException) {
        throw ApiException('Invalid response format from server', response.statusCode);
      } else {
        throw ApiException('Failed to parse response: ${response.body}', response.statusCode);
      }
    }
  }
  
  // Safely extract a human-readable message from various server error shapes
  static String _extractMessage(dynamic message) {
    if (message == null) return 'An unexpected error occurred';
    if (message is String) return message;
    if (message is List) {
      final parts = message.map((e) {
        if (e is String) return e;
        if (e is Map && e['message'] is String) return e['message'];
        return e.toString();
      }).cast<String>().toList();
      return parts.isEmpty ? 'An unexpected error occurred' : parts.join(' | ');
    }
    if (message is Map) {
      final inner = message['message'] ?? message['error'] ?? message['errors'] ?? message.toString();
      return _extractMessage(inner);
    }
    return message.toString();
  }

  static String _getErrorMessage(int statusCode, Map<String, dynamic>? data) {
    final String extracted = _extractMessage(data?['message']);
    switch (statusCode) {
      case 400:
        return extracted.isNotEmpty ? extracted : 'Bad request - please check your input';
      case 401:
        return 'Authentication failed - please login again';
      case 403:
        return 'Access denied - you do not have permission for this action';
      case 404:
        return extracted.isNotEmpty ? extracted : 'Resource not found';
      case 409:
        return extracted.isNotEmpty ? extracted : 'Conflict - resource already exists';
      case 422:
        return extracted.isNotEmpty ? extracted : 'Validation failed - please check your input';
      case 429:
        return 'Too many requests - please try again later';
      case 500:
        return extracted.isNotEmpty ? extracted : 'Server error - please try again later';
      case 503:
        return 'Service temporarily unavailable - please try again later';
      default:
        return extracted.isNotEmpty ? extracted : 'An unexpected error occurred';
    }
  }
  
  // Retry mechanism for API calls
  static Future<http.Response> _makeRequestWithRetry(
    Future<http.Response> Function() request,
    {int maxRetries = 3, Duration delay = const Duration(seconds: 1)}
  ) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        final response = await request();
        // Only retry on 5xx errors or network errors
        if (response.statusCode < 500) {
          return response;
        }
        
        attempts++;
        if (attempts >= maxRetries) {
          return response;
        }
        
        await Future.delayed(delay * attempts); // Exponential backoff
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
    
    throw ApiException('Max retry attempts exceeded', 0);
  }

  // Authentication APIs
  static Future<User> register({
    required String name,
    required String email,
    required String password,
    required String shopName,
    required String ownerName,
    required String city,
    String? phone,
    String? address,
  }) async {
    if (kDebugMode) {
      debugPrint('=== API SERVICE REGISTER DEBUG ===');
      debugPrint('Making request to: $_baseUrl/register');
    }
    
    final requestData = {
      'name': name,
      'email': email,
      'password': password,
      'shopName': shopName,
      'ownerName': ownerName,
      'city': city,
      'phone': phone,
      'address': address,
    };
    
    if (kDebugMode) {
      debugPrint('Request headers: ${_getHeaders()}');
      debugPrint('Request data: $requestData');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: _getHeaders(),
        body: json.encode(requestData),
      );
      
      if (kDebugMode) {
        debugPrint('Response status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
      
      final data = _handleResponse(response);
      if (kDebugMode) {
        debugPrint('Parsed response data: $data');
      }
      
      await _saveToken(data['data']['token']);
      if (kDebugMode) {
        debugPrint('Token saved successfully');
      }
      
      final user = User.fromJson(data['data']);
      if (kDebugMode) {
        debugPrint('User created successfully: ${user.toString()}');
      }
      return user;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in register API call: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  static Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: _getHeaders(),
      body: json.encode({
        'identifier': identifier,
        'password': password,
      }),
    );

    final data = _handleResponse(response);
    await _saveToken(data['data']['token']);
    return User.fromJson(data['data']);
  }

  static Future<void> logout() async {
    await _clearToken();
  }

  static Future<void> forgotPassword(String identifier) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forgot-password'),
      headers: _getHeaders(),
      body: json.encode({
        'identifier': identifier,
      }),
    );

    _handleResponse(response);
  }

  static bool get isLoggedIn => _token != null;

  // User APIs
  static Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: _getHeaders(),
    );

    final data = _handleResponse(response);
    return User.fromJson(data['data']);
  }

  static Future<User> updateProfile({
    required String name,
    String? shopName,
    String? ownerName,
    String? city,
    String? phone,
    String? address,
    String? avatar,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/me'),
      headers: _getHeaders(),
      body: json.encode({
        'name': name,
        'shopName': shopName,
        'ownerName': ownerName,
        'city': city,
        'phone': phone,
        'address': address,
        'avatar': avatar,
      }),
    );

    final data = _handleResponse(response);
    return User.fromJson(data['data']);
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/password'),
      headers: _getHeaders(),
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    _handleResponse(response);
  }

  static Future<void> deleteProfile(String password) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/me'),
      headers: _getHeaders(),
      body: json.encode({
        'password': password,
      }),
    );

    _handleResponse(response);
    await _clearToken();
  }

  // Product APIs
  static Future<List<Map<String, dynamic>>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
    String? brand,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (brand != null) queryParams['brand'] = brand;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final uri = Uri.parse('$_baseUrl/products').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());

    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
  }

  static Future<Map<String, dynamic>> getProduct(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _getHeaders(),
    );

    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    // Validate product data
    _validateProductData(productData);
    
    final response = await _makeRequestWithRetry(
      () => http.post(
        Uri.parse('$_baseUrl/products'),
        headers: _getHeaders(),
        body: json.encode(productData),
      ),
      maxRetries: 2, // Products are important, but don't retry too much
    );

    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }
  
  static void _validateProductData(Map<String, dynamic> productData) {
    if (productData['name'] == null || productData['name'].toString().trim().isEmpty) {
      throw ArgumentError('Product name is required');
    }
    
    if (productData['price'] == null || productData['price'] <= 0) {
      throw ArgumentError('Product price must be greater than zero');
    }
    
    if (productData['stock'] == null || productData['stock'] < 0) {
      throw ArgumentError('Product stock cannot be negative');
    }
    
    if (productData['category'] == null || productData['category'].toString().trim().isEmpty) {
      throw ArgumentError('Product category is required');
    }
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _getHeaders(),
      body: json.encode(productData),
    );

    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
  }

  // Customer APIs
  static Future<List<Map<String, dynamic>>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$_baseUrl/customers').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());

    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
  }

  static Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customerData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers'),
      headers: _getHeaders(),
      body: json.encode(customerData),
    );

    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> customerData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/customers/$id'),
      headers: _getHeaders(),
      body: json.encode(customerData),
    );

    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteCustomer(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/customers/$id'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
  }

  // Sales APIs with improved error handling and validation
  static Future<Map<String, dynamic>> createSale(Map<String, dynamic> saleData) async {
    // Validate sale data before sending
    _validateSaleData(saleData);
    
    final response = await _makeRequestWithRetry(
      () => http.post(
        Uri.parse('$_baseUrl/sales'),
        headers: _getHeaders(),
        body: json.encode(saleData),
      ),
    );

    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }
  
  static void _validateSaleData(Map<String, dynamic> saleData) {
    if (saleData['items'] == null || (saleData['items'] as List).isEmpty) {
      throw ArgumentError('Sale must contain at least one item');
    }
    
    if (saleData['total'] == null || saleData['total'] <= 0) {
      throw ArgumentError('Sale total must be greater than zero');
    }
    
    final items = saleData['items'] as List;
    for (var item in items) {
      if (item['quantity'] == null || item['quantity'] <= 0) {
        throw ArgumentError('All items must have quantity greater than zero');
      }
      if (item['unitPrice'] == null || item['unitPrice'] <= 0) {
        throw ArgumentError('All items must have unit price greater than zero');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getSales({
    int page = 1,
    int limit = 10,
    String? status,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (paymentStatus != null) queryParams['paymentStatus'] = paymentStatus;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final uri = Uri.parse('$_baseUrl/sales').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());

    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
  }

  static Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};

    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final uri = Uri.parse('$_baseUrl/sales/report').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());

    final data = _handleResponse(response);
    return data['data'];
  }

  // Enhanced Customer APIs
  static Future<Map<String, dynamic>> addVehicleToCustomer(String customerId, Map<String, dynamic> vehicleData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers/$customerId/vehicles'),
      headers: _getHeaders(),
      body: json.encode(vehicleData),
    );
    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateVehicle(String customerId, String vehicleId, Map<String, dynamic> vehicleData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/customers/$customerId/vehicles/$vehicleId'),
      headers: _getHeaders(),
      body: json.encode(vehicleData),
    );
    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addOilChangeHistory(String customerId, Map<String, dynamic> oilChangeData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers/$customerId/oil-change'),
      headers: _getHeaders(),
      body: json.encode(oilChangeData),
    );
    final data = _handleResponse(response);
    return data['data'] as Map<String, dynamic>;
  }


  static Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/top-customers?limit=$limit'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
  }

  // Feedback APIs
  static Future<Feedback> submitFeedback(Map<String, dynamic> feedbackData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/feedback'),
      headers: _getHeaders(),
      body: json.encode(feedbackData),
    );
    final data = _handleResponse(response);
    return Feedback.fromJson(data['data']);
  }

  static Future<List<Feedback>> getMyFeedbacks({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('$_baseUrl/feedback/my').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    return List<Feedback>.from(data['data'].map((item) => Feedback.fromJson(item)));
  }

  static Future<void> deleteFeedback(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/feedback/$id'),
      headers: _getHeaders(),
    );
    _handleResponse(response);
  }

  // Advanced Reports APIs
  static Future<Map<String, dynamic>> getDailyReport({DateTime? date}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date.toIso8601String();
    
    final uri = Uri.parse('$_baseUrl/reports/daily').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getWeeklyReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    
    final uri = Uri.parse('$_baseUrl/reports/weekly').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getMonthlyReport({
    int? year,
    int? month,
  }) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();
    
    final uri = Uri.parse('$_baseUrl/reports/monthly').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getComparisonReport() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/comparison'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getLowStockReport() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/low-stock'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getCustomerReport() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/customers'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> exportReport(String type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    
    final uri = Uri.parse('$_baseUrl/reports/export/$type').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    return data;
  }

  // Enhanced Product APIs
  static Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/lowstock'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
  }

  // Enhanced Analytics APIs (Phase 3)
  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/dashboard'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getDailyAnalytics({DateTime? date}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date.toIso8601String();
    
    final uri = Uri.parse('$_baseUrl/analytics/daily').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getWeeklyAnalytics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/weekly'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getMonthlyAnalytics({int? year, int? month}) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();
    
    final uri = Uri.parse('$_baseUrl/analytics/monthly').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getInventoryAnalytics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/inventory'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getCustomerAnalytics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/customers'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> exportAnalytics(String type) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/export/$type'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data;
  }

}


