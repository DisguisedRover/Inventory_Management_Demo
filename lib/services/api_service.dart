import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/inventory_item.dart';
import '../models/order.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final String baseurl = 'http://192.168.18.90:8080/dairy';

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Check if response is HTML
      if (response.body.trim().toLowerCase().startsWith('<!doctype html>') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        print(
            'Received HTML instead of JSON: ${response.body}'); // Debugging Line
        throw ApiException(
          'Server returned HTML instead of JSON. Please check the API endpoint.',
          statusCode: response.statusCode,
        );
      }

      // Try to parse as JSON to verify response format
      try {
        jsonDecode(response.body);
      } catch (e) {
        throw ApiException(
          'Invalid JSON response from server',
          statusCode: response.statusCode,
        );
      }
    } else {
      // Handle error responses
      String message;
      try {
        final errorData = jsonDecode(response.body);
        message = errorData['message'] ?? 'Unknown error occurred';
      } catch (e) {
        message = 'Server error: ${response.statusCode}';
      }
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  Future<List<InventoryItem>> getInventory() async {
    final response = await http.get(Uri.parse('$baseurl/inventory'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InventoryItem.fromJson(json)).toList();
    }
    throw Exception('Failed to load inventory');
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseurl/orderReceive'));
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Decoded JSON data: $data');

        return data.map((json) {
          try {
            final order = Order.fromJson(json);
            print('Successfully parsed order: $order');
            return order;
          } catch (e, stackTrace) {
            print('Error parsing individual order:');
            print('JSON: $json');
            print('Error: $e');
            print('Stack trace: $stackTrace');
            rethrow;
          }
        }).toList();
      }

      throw ApiException('Failed to load orders',
          statusCode: response.statusCode);
    } catch (e, stackTrace) {
      print('Error in getOrders:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> createOrder(
      int itemId, String name, String contact, String address) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseurl/orderReceive'), // Note: Changed from /order to /orders to match backend
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'item_id': itemId,
          'name': name,
          'contact': contact,
          'address': address,
        }),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 201) {
        var errorMessage = 'Failed to create order';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          print('Error parsing error response: $e');
        }
        throw ApiException(
            '$errorMessage (Status: ${response.statusCode})\nResponse: ${response.body}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<void> addInventoryItem(
      String title, double price, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseurl/inventory'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'title': title,
          'price': price,
          'quantity': quantity,
        }),
      );

      _checkResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to server: ${e.toString()}');
    }
  }

  Future<void> updateInventoryItem(
      int id, String title, double price, int quantity) async {
    try {
      final response = await http.put(
        Uri.parse('$baseurl/inventory/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'title': title,
          'price': price,
          'quantity': quantity,
        }),
      );

      _checkResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to server: ${e.toString()}');
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseurl/inventory/$id'),
        headers: {
          'Accept': 'application/json',
        },
      );

      _checkResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to server: ${e.toString()}');
    }
  }
}
