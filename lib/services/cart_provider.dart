import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

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

    notifyListeners();
  }

  // =========================
  // REMOVE ITEM
  // =========================
  void removeFromCart(int productId) {

    _items.removeWhere((item) => item.product.id == productId);

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

      notifyListeners();
    }
  }
}