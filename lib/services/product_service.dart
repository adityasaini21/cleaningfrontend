import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/product.dart';
import 'auth_service.dart';

class ProductService {

  // =========================================
  // BASE URL
  // =========================================

  // Android Emulator
  static const String baseUrl =
      "http://10.0.2.2:8080";

  // =========================================
  // COMMON HEADERS
  // =========================================
  Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${AuthService.token}",
  };

  // =========================================
  // FETCH PRODUCTS WITH PAGINATION
  // =========================================
  Future<List<Product>> fetchProducts(int page) async {

    try {

      final response = await http.get(

        Uri.parse(
          "$baseUrl/api/products/paged?page=$page&size=50",
        ),

        headers: headers,
      );

      print("FETCH PRODUCTS STATUS: ${response.statusCode}");
      print("FETCH PRODUCTS BODY: ${response.body}");

      if (response.statusCode == 200) {

        final Map<String, dynamic> jsonData =
        jsonDecode(response.body);

        final List<dynamic> productList =
            jsonData["content"] ?? [];

        return productList
            .map((e) => Product.fromJson(e))
            .toList();

      } else {

        throw Exception(
          "Failed to load products",
        );
      }

    } catch (e) {

      print("FETCH PRODUCTS ERROR: $e");

      return [];
    }
  }

  // =========================================
  // FETCH DELETED PRODUCTS
  // =========================================
  Future<List<Product>> fetchDeletedProducts() async {

    try {

      final response = await http.get(

        Uri.parse(
          "$baseUrl/api/products/deleted",
        ),

        headers: headers,
      );

      print("DELETED PRODUCTS STATUS: ${response.statusCode}");
      print("DELETED PRODUCTS BODY: ${response.body}");

      if (response.statusCode == 200) {

        final List<dynamic> data =
        jsonDecode(response.body);

        return data
            .map((e) => Product.fromJson(e))
            .toList();

      } else {

        throw Exception(
          "Failed to load deleted products",
        );
      }

    } catch (e) {

      print("DELETED PRODUCTS ERROR: $e");

      return [];
    }
  }

  // =========================================
  // RESTORE PRODUCT
  // =========================================
  Future<void> restoreProduct(int productId) async {

    final response = await http.put(

      Uri.parse(
        "$baseUrl/api/products/$productId/restore",
      ),

      headers: headers,
    );

    print("RESTORE STATUS: ${response.statusCode}");
    print("RESTORE BODY: ${response.body}");

    if (response.statusCode != 200) {

      throw Exception(
        "Failed to restore product",
      );
    }
  }

  // =========================================
  // FETCH PRODUCTS BY CATEGORY
  // =========================================
  Future<List<Product>> fetchProductsByCategory(
      String categoryName) async {

    try {

      final response = await http.get(

        Uri.parse(
          "$baseUrl/api/products?category=${Uri.encodeComponent(categoryName)}",
        ),

        headers: headers,
      );

      print("CATEGORY PRODUCTS STATUS: ${response.statusCode}");
      print("CATEGORY PRODUCTS BODY: ${response.body}");

      if (response.statusCode == 200) {

        final List<dynamic> productList =
        jsonDecode(response.body);

        return productList
            .map((e) => Product.fromJson(e))
            .toList();

      } else {

        throw Exception(
          "Failed to load category products",
        );
      }

    } catch (e) {

      print("CATEGORY PRODUCTS ERROR: $e");

      return [];
    }
  }

  // =========================================
  // FETCH CATEGORIES
  // =========================================
  Future<List<Category>> fetchCategories() async {

    try {

      final response = await http.get(

        Uri.parse(
          "$baseUrl/api/categories",
        ),

        headers: headers,
      );

      print("CATEGORIES STATUS: ${response.statusCode}");
      print("CATEGORIES BODY: ${response.body}");

      if (response.statusCode == 200) {

        final List<dynamic> data =
        jsonDecode(response.body);

        return data
            .map((e) => Category.fromJson(e))
            .toList();

      } else {

        throw Exception(
          "Failed to load categories",
        );
      }

    } catch (e) {

      print("CATEGORIES ERROR: $e");

      return [];
    }
  }

  // =========================================
  // CREATE PRODUCT
  // =========================================
  Future<void> createProduct({

    required String name,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
    required int categoryId,

  }) async {

    final body = {

      "name": name,
      "description": description,
      "price": price,
      "costPrice": price,
      "stock": stock,
      "imageUrl": imageUrl,
      "categoryId": categoryId,
    };

    print("CREATE BODY: ${jsonEncode(body)}");

    final response = await http.post(

      Uri.parse(
        "$baseUrl/api/products",
      ),

      headers: headers,

      body: jsonEncode(body),
    );

    print("CREATE STATUS: ${response.statusCode}");
    print("CREATE RESPONSE: ${response.body}");

    if (response.statusCode != 201 &&
        response.statusCode != 200) {

      throw Exception(
        "Failed to create product",
      );
    }
  }

  // =========================================
  // DELETE PRODUCT
  // =========================================
  Future<void> deleteProduct(int productId) async {

    final response = await http.delete(

      Uri.parse(
        "$baseUrl/api/products/$productId",
      ),

      headers: headers,
    );

    print("DELETE STATUS: ${response.statusCode}");
    print("DELETE RESPONSE: ${response.body}");

    if (response.statusCode != 204 &&
        response.statusCode != 200) {

      throw Exception(
        "Failed to delete product",
      );
    }
  }

  // =========================================
  // UPDATE PRODUCT
  // =========================================
  Future<void> updateProduct({

    required int productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
    required int categoryId,

  }) async {

    final body = {

      "name": name,
      "description": description,
      "price": price,
      "costPrice": price,
      "stock": stock,
      "imageUrl": imageUrl,
      "categoryId": categoryId,
    };

    print("UPDATE BODY: ${jsonEncode(body)}");

    final response = await http.put(

      Uri.parse(
        "$baseUrl/api/products/$productId",
      ),

      headers: headers,

      body: jsonEncode(body),
    );

    print("UPDATE STATUS: ${response.statusCode}");
    print("UPDATE RESPONSE: ${response.body}");

    if (response.statusCode != 200) {

      throw Exception(
        "Failed to update product",
      );
    }
  }
}