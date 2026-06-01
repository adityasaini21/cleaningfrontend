import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import 'auth_service.dart';

class OrderHistoryService {

  final String baseUrl =
      "http://10.0.2.2:8080";

  // =========================================
  // COMMON HEADERS
  // =========================================
  Map<String, String> get _headers {

    return {

      "Content-Type": "application/json",

      "Authorization":
      "Bearer ${AuthService.token}",
    };
  }

  // =========================================
  // USER: FETCH MY ORDERS
  // =========================================
  Future<List<OrderModel>> fetchMyOrders() async {

    final response = await http.get(

      Uri.parse("$baseUrl/api/orders/my"),

      headers: _headers,
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {

      final List data =
      jsonDecode(response.body);

      return data
          .map((e) => OrderModel.fromJson(e))
          .toList();

    } else {

      throw Exception(
        "Failed to load orders: ${response.body}",
      );
    }
  }

  // =========================================
  // USER: CANCEL ORDER
  // =========================================
  Future<void> cancelOrder(int orderId) async {

    final response = await http.put(

      Uri.parse(
        "$baseUrl/api/orders/$orderId/cancel",
      ),

      headers: _headers,
    );

    if (response.statusCode != 200) {

      throw Exception("Cancel failed");
    }
  }

  // =========================================
  // 🔥 ADMIN: FETCH ALL ORDERS
  // =========================================
  Future<List<OrderModel>> fetchAllOrders() async {

    final response = await http.get(

      Uri.parse("$baseUrl/api/orders/all"),

      headers: _headers,
    );

    print("ADMIN STATUS: ${response.statusCode}");
    print("ADMIN BODY: ${response.body}");

    if (response.statusCode == 200) {

      final List data =
      jsonDecode(response.body);

      return data
          .map((e) => OrderModel.fromJson(e))
          .toList();

    } else {

      throw Exception(
        "Failed to load admin orders",
      );
    }
  }

  // =========================================
  // 🔥 ADMIN: UPDATE ORDER STATUS
  // =========================================
  Future<void> updateOrderStatus({

    required int orderId,

    required String status,

  }) async {

    final response = await http.put(

      Uri.parse(
        "$baseUrl/api/orders/$orderId/status?status=$status",
      ),

      headers: _headers,
    );

    print(
      "UPDATE STATUS CODE: ${response.statusCode}",
    );

    print(
      "UPDATE BODY: ${response.body}",
    );

    if (response.statusCode != 200) {

      throw Exception(
        "Failed to update order status",
      );
    }
  }

  // =========================================
// 🔥 ADMIN: ASSIGN DELIVERY BOY
// =========================================
  Future<void> assignDeliveryBoy({

    required int orderId,

    required String deliveryBoyName,

    required String deliveryBoyPhone,

  }) async {

    final response = await http.put(

      Uri.parse(
        "$baseUrl/api/orders/$orderId/assign-delivery",
      ),

      headers: _headers,

      body: jsonEncode({

        "deliveryBoyName": deliveryBoyName,

        "deliveryBoyPhone": deliveryBoyPhone,
      }),
    );

    print(
      "ASSIGN DELIVERY STATUS: ${response.statusCode}",
    );

    print(
      "ASSIGN DELIVERY BODY: ${response.body}",
    );

    if (response.statusCode != 200) {

      throw Exception(
        "Failed to assign delivery boy",
      );
    }
  }
}