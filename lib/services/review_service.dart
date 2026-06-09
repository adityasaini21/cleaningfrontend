import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../models/review.dart';
import 'auth_service.dart';

class ReviewService {

  static const String baseUrl =
      "http://10.0.2.2:8080/api/reviews";

  Future<List<Review>> getProductReviews(
      int productId) async {

    final response = await http.get(
      Uri.parse(
        "$baseUrl/product/$productId",
      ),
    );

    debugPrint(
      "REVIEW STATUS: ${response.statusCode}",
    );

    debugPrint(
      "REVIEW BODY: ${response.body}",
    );

    if (response.statusCode == 200) {

      final List data =
      jsonDecode(response.body);

      return data
          .map((e) => Review.fromJson(e))
          .toList();
    }

    throw Exception(
      "Failed to load reviews. Status: ${response.statusCode}",
    );
  }

  Future<void> addReview({

    required int productId,

    required int rating,

    required String comment,

  }) async {

    final token = AuthService.token;

    if (token == null) {

      throw Exception("User not logged in");

    }

    final response = await http.post(

      Uri.parse(baseUrl),

      headers: {

        "Content-Type":
        "application/json",

        "Authorization":
        "Bearer $token",
      },

      body: jsonEncode({

        "productId": productId,

        "rating": rating,

        "comment": comment,
      }),
    );

    if (response.statusCode != 200) {

      throw Exception(
        "Failed to add review",
      );
    }
  }
  Future<bool> canReview(
      int productId,
      ) async {

    final token = AuthService.token;

    final response = await http.get(

      Uri.parse(
        "$baseUrl/can-review/$productId",
      ),

      headers: {

        "Authorization":
        "Bearer $token",
      },
    );

    if (response.statusCode == 200) {

      return jsonDecode(response.body);
    }

    throw Exception(
      "Failed to check review permission",
    );
  }
}