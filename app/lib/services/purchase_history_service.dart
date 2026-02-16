import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/purchase_history.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';

class PurchaseHistoryService {
  final String baseUrl = ApiConfig.baseUrl;

  // Get authentication token (implement based on your auth system)
  Future<String?> _getAuthToken() async {
    // TODO: Implement token retrieval from secure storage
    return null;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get complete purchase history for a customer
  Future<Map<String, dynamic>> getCustomerPurchaseHistory(
    String customerId, {
    int limit = 50,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse('$baseUrl/purchase-history/$customerId')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'purchases': (data['data']['purchases'] as List)
              .map((item) => PurchaseHistory.fromJson(item))
              .toList(),
          'pagination': data['data']['pagination'],
        };
      } else {
        throw Exception('Failed to load purchase history');
      }
    } catch (e) {
      Logger.error('Error fetching purchase history: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get purchase summary for a customer
  Future<PurchaseSummary?> getCustomerPurchaseSummary(
      String customerId) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-history/$customerId/summary');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PurchaseSummary.fromJson(data['data']);
      } else {
        throw Exception('Failed to load purchase summary');
      }
    } catch (e) {
      Logger.error('Error fetching purchase summary: $e');
      return null;
    }
  }

  /// Get detailed information for a specific sale
  Future<Map<String, dynamic>?> getSaleDetails(String saleId) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-history/sale/$saleId');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load sale details');
      }
    } catch (e) {
      Logger.error('Error fetching sale details: $e');
      return null;
    }
  }

  /// Get customer's product preferences
  Future<List<ProductPreference>> getCustomerProductPreferences(
    String customerId, {
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
              '$baseUrl/purchase-history/$customerId/preferences')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((item) => ProductPreference.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load product preferences');
      }
    } catch (e) {
      Logger.error('Error fetching product preferences: $e');
      return [];
    }
  }

  /// Get purchase history by date range
  Future<List<PurchaseHistory>> getPurchaseHistoryByDateRange(
    String customerId,
    String startDate,
    String endDate,
  ) async {
    try {
      final uri = Uri.parse(
              '$baseUrl/purchase-history/$customerId/date-range')
          .replace(queryParameters: {
        'startDate': startDate,
        'endDate': endDate,
      });

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((item) => PurchaseHistory.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load purchase history');
      }
    } catch (e) {
      Logger.error('Error fetching purchase history by date: $e');
      return [];
    }
  }

  /// Calculate customer lifetime value
  Future<CustomerLifetimeValue?> getCustomerLifetimeValue(
      String customerId) async {
    try {
      final uri =
          Uri.parse('$baseUrl/purchase-history/$customerId/lifetime-value');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CustomerLifetimeValue.fromJson(data['data']);
      } else {
        throw Exception('Failed to load customer lifetime value');
      }
    } catch (e) {
      Logger.error('Error fetching customer lifetime value: $e');
      return null;
    }
  }

  /// Get customer loyalty metrics
  Future<Map<String, dynamic>?> getCustomerLoyaltyMetrics(
      String customerId) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-history/$customerId/loyalty');
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to load loyalty metrics');
      }
    } catch (e) {
      Logger.error('Error fetching loyalty metrics: $e');
      return null;
    }
  }

  /// Get monthly purchase trends
  Future<List<MonthlyTrend>> getMonthlyPurchaseTrends(
    String customerId, {
    int months = 12,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-history/$customerId/trends')
          .replace(queryParameters: {'months': months.toString()});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((item) => MonthlyTrend.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load monthly trends');
      }
    } catch (e) {
      Logger.error('Error fetching monthly trends: $e');
      return [];
    }
  }

  /// Search purchase history
  Future<List<PurchaseHistory>> searchPurchaseHistory(
    String customerId,
    String query, {
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase-history/$customerId/search')
          .replace(queryParameters: {
        'query': query,
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((item) => PurchaseHistory.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to search purchase history');
      }
    } catch (e) {
      Logger.error('Error searching purchase history: $e');
      return [];
    }
  }

  /// Export purchase history to CSV
  Future<String?> exportPurchaseHistory(
    String customerId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse('$baseUrl/purchase-history/$customerId/export')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.body; // CSV content
      } else {
        throw Exception('Failed to export purchase history');
      }
    } catch (e) {
      Logger.error('Error exporting purchase history: $e');
      return null;
    }
  }
}
