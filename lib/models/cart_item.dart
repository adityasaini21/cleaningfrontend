import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<dynamic, dynamic> json) {
    final productRaw = json['product'];
    final Map<dynamic, dynamic> productMap = productRaw is Map ? productRaw : {};
    return CartItem(
      product: Product.fromJson(productMap),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}