import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lpg_product.dart';
import '../models/lpg_customer.dart';
import '../config/api_config.dart';

class LPGApiException implements Exception {
  final String message;
  final int statusCode;
  
  LPGApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'LPGApiException: $message (Status: $statusCode)';
  
  bool get isNetworkError => statusCode == 0;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isAuthError => statusCode == 401;
}

class LPGApiService {
  static String get _baseUrl => ApiConfig.lpgBaseUrl;
  static String? _token;

  // Initialize token from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
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

  // Handle HTTP response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      String message = 'Request failed';
      try {
        final errorData = json.decode(response.body);
        message = errorData['message'] ?? message;
      } catch (e) {
        // Use default message if JSON parsing fails
      }
      throw LPGApiException(message, response.statusCode);
    }
  }

  // Build a public URL for static assets
  static String publicUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('data:')) return path;
    
    final uri = Uri.parse(_baseUrl);
    final origin = uri.hasPort && uri.port != 0
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
    
    if (path.startsWith('/')) return '$origin$path';
    return '$origin/$path';
  }

  // --- LPG Product APIs ---

  static Future<List<LPGProduct>> getLPGProducts({
    int page = 1,
    int limit = 10,
    String? category,
    String? productType,
    String? cylinderType,
    String? brand,
    String? search,
    String? stockStatus,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (productType != null) queryParams['productType'] = productType;
    if (cylinderType != null) queryParams['cylinderType'] = cylinderType;
    if (brand != null) queryParams['brand'] = brand;
    if (search != null) queryParams['search'] = search;
    if (stockStatus != null) queryParams['stockStatus'] = stockStatus;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final uri = Uri.parse('$_baseUrl/products').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    
    return (data['data'] as List)
        .map((json) => LPGProduct.fromJson(json))
        .toList();
  }

  static Future<LPGProduct> getLPGProduct(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return LPGProduct.fromJson(data['data']);
  }

  static Future<LPGProduct> createLPGProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: _getHeaders(),
      body: json.encode(productData),
    );
    final data = _handleResponse(response);
    return LPGProduct.fromJson(data['data']);
  }

  static Future<LPGProduct> updateLPGProduct(String id, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _getHeaders(),
      body: json.encode(productData),
    );
    final data = _handleResponse(response);
    return LPGProduct.fromJson(data['data']);
  }

  static Future<void> deleteLPGProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _getHeaders(),
    );
    _handleResponse(response);
  }

  static Future<LPGProduct> updateCylinderState(
    String id,
    String state,
    int quantity, {
    String operation = 'add',
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$id/cylinder-state'),
      headers: _getHeaders(),
      body: json.encode({
        'state': state,
        'quantity': quantity,
        'operation': operation,
      }),
    );
    final data = _handleResponse(response);
    return LPGProduct.fromJson(data['data']);
  }

  static Future<LPGProduct> exchangeCylinder(String id, int quantity) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$id/exchange'),
      headers: _getHeaders(),
      body: json.encode({'quantity': quantity}),
    );
    final data = _handleResponse(response);
    return LPGProduct.fromJson(data['data']);
  }

  static Future<List<LPGProduct>> getLowStockProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/low-stock'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return (data['data'] as List)
        .map((json) => LPGProduct.fromJson(json))
        .toList();
  }

  static Future<List<LPGProduct>> getProductsByCategory(String category, {
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    final uri = Uri.parse('$_baseUrl/products/category/$category')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    
    return (data['data'] as List)
        .map((json) => LPGProduct.fromJson(json))
        .toList();
  }

  static Future<Map<String, dynamic>> getCylinderSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/cylinder-summary'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<List<LPGProduct>> getProductsDueForInspection({int days = 30}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/inspection-due?days=$days'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return (data['data'] as List)
        .map((json) => LPGProduct.fromJson(json))
        .toList();
  }

  // --- LPG Customer APIs ---

  static Future<List<LPGCustomer>> getLPGCustomers({
    int page = 1,
    int limit = 10,
    String? search,
    String? customerType,
    String? loyaltyTier,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null) queryParams['search'] = search;
    if (customerType != null) queryParams['customerType'] = customerType;
    if (loyaltyTier != null) queryParams['loyaltyTier'] = loyaltyTier;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final uri = Uri.parse('$_baseUrl/customers').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    
    return (data['data'] as List)
        .map((json) => LPGCustomer.fromJson(json))
        .toList();
  }

  static Future<LPGCustomer> getLPGCustomer(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/$id'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<LPGCustomer> createLPGCustomer(Map<String, dynamic> customerData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers'),
      headers: _getHeaders(),
      body: json.encode(customerData),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<LPGCustomer> updateLPGCustomer(String id, Map<String, dynamic> customerData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/customers/$id'),
      headers: _getHeaders(),
      body: json.encode(customerData),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<void> deleteLPGCustomer(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/customers/$id'),
      headers: _getHeaders(),
    );
    _handleResponse(response);
  }

  static Future<LPGCustomer> addPremises(String customerId, Map<String, dynamic> premisesData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers/$customerId/premises'),
      headers: _getHeaders(),
      body: json.encode(premisesData),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<LPGCustomer> updatePremises(
    String customerId,
    String premisesId,
    Map<String, dynamic> premisesData,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/customers/$customerId/premises/$premisesId'),
      headers: _getHeaders(),
      body: json.encode(premisesData),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<LPGCustomer> removePremises(String customerId, String premisesId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/customers/$customerId/premises/$premisesId'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<LPGCustomer> addRefillRecord(
    String customerId,
    Map<String, dynamic> refillData,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers/$customerId/refill'),
      headers: _getHeaders(),
      body: json.encode(refillData),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<List<CylinderRefillHistory>> getRefillHistory(
    String customerId, {
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    final uri = Uri.parse('$_baseUrl/customers/$customerId/refill-history')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    
    return (data['data'] as List)
        .map((json) => CylinderRefillHistory.fromJson(json))
        .toList();
  }

  static Future<LPGCustomer> updateCredit(
    String customerId,
    double amount, {
    String operation = 'add',
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/customers/$customerId/credit'),
      headers: _getHeaders(),
      body: json.encode({
        'amount': amount,
        'operation': operation,
      }),
    );
    final data = _handleResponse(response);
    return LPGCustomer.fromJson(data['data']);
  }

  static Future<List<LPGCustomer>> getCustomersDueForRefill({int days = 7}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/due-refill?days=$days'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return (data['data'] as List)
        .map((json) => LPGCustomer.fromJson(json))
        .toList();
  }

  static Future<List<LPGCustomer>> getTopCustomers({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/top-customers?limit=$limit'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return (data['data'] as List)
        .map((json) => LPGCustomer.fromJson(json))
        .toList();
  }

  static Future<Map<String, dynamic>> getCustomerAnalytics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/analytics'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> getConsumptionPattern(String customerId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/customers/$customerId/consumption-pattern'),
      headers: _getHeaders(),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  // --- LPG Sales APIs ---

  static Future<Map<String, dynamic>> createLPGSale(Map<String, dynamic> saleData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sales'),
      headers: _getHeaders(),
      body: json.encode(saleData),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<List<Map<String, dynamic>>> getLPGSales({
    int page = 1,
    int limit = 10,
    String? startDate,
    String? endDate,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$_baseUrl/sales').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    
    return List<Map<String, dynamic>>.from(data['data']);
  }

  static Future<Map<String, dynamic>> getSalesReport({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final uri = Uri.parse('$_baseUrl/sales/report').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _getHeaders());
    final data = _handleResponse(response);
    
    return data['data'];
  }
}