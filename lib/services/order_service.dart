import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../models/cart_item.dart';

class OrderService {

  final String baseUrl =
      "http://10.0.2.2:8080";

  // =========================================
  // CHECK DELIVERY PINCODE
  // =========================================

  Future<bool> checkPincode(
      String pincode) async {

    try {

      final response = await http.get(

        Uri.parse(
          "$baseUrl/api/pincode/check/$pincode",
        ),

        headers: {
          "Authorization":
          "Bearer ${AuthService.token}",
        },
      );

      if (response.statusCode == 200) {

        final data =
        jsonDecode(response.body);

        return data["deliverable"] == true;
      }

      return false;

    } catch (e) {

      print("PINCODE CHECK ERROR: $e");

      return false;
    }
  }

  // =========================================
  // CREATE ORDER
  // =========================================

  Future<int?> placeOrder({

    required String shippingAddress,

    required String phoneNumber,

    required String pincode,


    required String paymentMethod,

    required List<CartItem> items,

  }) async {

    print("========== ORDER PAYLOAD ==========");

    print(jsonEncode({

      "shippingAddress": shippingAddress,

      "phoneNumber": phoneNumber,

      "pincode": pincode,

      "paymentMethod": paymentMethod,

      "items": items.map((item) => {

        "productId": item.product.id,

        "quantity": item.quantity,

      }).toList(),

    }));

    print("===================================");

    final response = await http.post(

      Uri.parse("$baseUrl/api/orders"),

      headers: {

        "Content-Type":
        "application/json",

        "Authorization":
        "Bearer ${AuthService.token}",
      },

      body: jsonEncode({

        "shippingAddress":
        shippingAddress,

        "phoneNumber":
        phoneNumber,

        "pincode": pincode,

        "paymentMethod":
        paymentMethod,

        "items": items.map((item) => {

          "productId":
          item.product.id,

          "quantity":
          item.quantity,

        }).toList(),
      }),
    );

    print(
      "STATUS CODE: ${response.statusCode}",
    );

    print(
      "RESPONSE BODY: ${response.body}",
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {

      final data =
      jsonDecode(response.body);

      return data["orderId"];
    }

    return null;
  }

  // =========================================
  // CREATE RAZORPAY ORDER
  // =========================================

  Future<String?> createRazorpayOrder(
      int orderId) async {

    final response = await http.post(

      Uri.parse(
        "$baseUrl/api/orders/$orderId/pay",
      ),

      headers: {

        "Authorization":
        "Bearer ${AuthService.token}",
      },
    );

    if (response.statusCode == 200) {

      return response.body;
    }

    print(
      "Payment API ERROR: ${response.body}",
    );

    return null;
  }

  // =========================================
  // VERIFY PAYMENT
  // =========================================

  Future<bool> verifyPayment({

    required int orderId,

    required String razorpayOrderId,

    required String razorpayPaymentId,

    required String razorpaySignature,

  }) async {

    final response = await http.post(

      Uri.parse(
        "$baseUrl/api/payments/verify/$orderId",
      ),

      headers: {

        "Content-Type":
        "application/json",

        "Authorization":
        "Bearer ${AuthService.token}",
      },

      body: jsonEncode({

        "razorpay_order_id":
        razorpayOrderId,

        "razorpay_payment_id":
        razorpayPaymentId,

        "razorpay_signature":
        razorpaySignature,
      }),
    );

    return response.statusCode == 200;
  }
}