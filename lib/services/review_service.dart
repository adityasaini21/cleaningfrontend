import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../models/review.dart';
import '../models/review_summary.dart';
import 'auth_service.dart';
import '../core/api_client.dart';

class ReviewService {

  static String get baseUrl =>
      "${ApiClient.baseUrl}/api/reviews";

  Future<ReviewSummary> getProductReviews(
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

      final data =
      jsonDecode(response.body);

      return ReviewSummary.fromJson(data);
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
    debugPrint("JWT: $token");
    debugPrint("PRODUCT ID: $productId");
    debugPrint("RATING: $rating");
    debugPrint("COMMENT: $comment");

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

      debugPrint("ADD REVIEW STATUS: ${response.statusCode}");
      debugPrint("ADD REVIEW BODY: ${response.body}");

      throw Exception(
        "Status: ${response.statusCode}\n${response.body}",
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

  Future<void> markHelpful(
      int reviewId,
      ) async {

    final token = AuthService.token;

    final response = await http.post(

      Uri.parse(
        "$baseUrl/$reviewId/helpful",
      ),

      headers: {

        "Authorization":
        "Bearer $token",
      },
    );

    if (response.statusCode != 200) {

      throw Exception(
        "Failed to mark helpful",
      );
    }
  }
}