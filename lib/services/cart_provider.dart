import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  static const String _cartStorageKey = "SAVED_CART_ITEMS_V1";

  final List<CartItem> _items = [];

  CartProvider() {
    loadCart();
  }

  List<CartItem> get items => _items;

  // =========================
  // PERSISTENCE METHODS
  // =========================
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJsonString = prefs.getString(_cartStorageKey);
      if (cartJsonString != null && cartJsonString.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(cartJsonString);
        _items.clear();
        for (final item in decodedList) {
          try {
            if (item is Map) {
              _items.add(CartItem.fromJson(item));
            }
          } catch (e) {
            debugPrint("Cart item parse error: $e");
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Load cart from storage error: $e");
    }
  }

  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJsonList = _items.map((item) => item.toJson()).toList();
      await prefs.setString(_cartStorageKey, jsonEncode(cartJsonList));
    } catch (e) {
      debugPrint("Save cart to storage error: $e");
    }
  }

  // =========================
  // ADD TO CART
  // =========================
  void addToCart(Product product) {

    final index =
    _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    _saveCartToStorage();
    notifyListeners();
  }

  // =========================
  // 🔥 ADD WITH QUANTITY (NEW)
  // =========================
  void addToCartWithQuantity(Product product, int quantity) {

    final index =
    _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {

      CartItem cartItem = CartItem(product: product);

      cartItem.quantity = quantity;

      _items.add(cartItem);
    }

    _saveCartToStorage();
    notifyListeners();
  }

  // =========================
  // REMOVE ITEM
  // =========================
  void removeFromCart(int productId) {

    _items.removeWhere((item) => item.product.id == productId);

    _saveCartToStorage();
    notifyListeners();
  }

  // =========================
  // TOTAL
  // =========================
  double get totalAmount {

    return _items.fold(
        0,
            (sum, item) => sum + item.totalPrice
    );
  }

  // =========================
  // CLEAR CART
  // =========================
  void clearCart() {

    _items.clear();

    _saveCartToStorage();
    notifyListeners();
  }

  // =========================
  // INCREASE
  // =========================
  void increaseQuantity(int productId) {

    final index =
    _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      _items[index].quantity++;
      _saveCartToStorage();
      notifyListeners();
    }
  }

  // =========================
  // DECREASE
  // =========================
  void decreaseQuantity(int productId) {

    final index =
    _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {

      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }

      _saveCartToStorage();
      notifyListeners();
    }
  }

  // =========================
  // GET QUANTITY BY PRODUCT ID
  // =========================
  int getProductQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      return _items[index].quantity;
    }
    return 0;
  }

  // =========================
  // TOTAL ITEM COUNT
  // =========================
  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }
}