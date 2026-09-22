class OrderItemModel {

  final int productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {

    return OrderItemModel(

      productId: json['productId'] ?? 0,

      productName: json['productName'] ?? "",

      quantity: json['quantity'] ?? 0,

      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class OrderModel {

  final int orderId;

  final String orderStatus;
  final String paymentStatus;

  final double totalAmount;

  final String shippingAddress;
  final String phoneNumber;
  final String customerName;
  final String pincode;

  // 🚚 Delivery Boy Details
  final String deliveryBoyName;
  final String deliveryBoyPhone;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  String get orderCode => "NUK$orderId";

  OrderModel({
    required this.orderId,
    required this.orderStatus,
    required this.paymentStatus,
    required this.totalAmount,
    required this.shippingAddress,
    required this.phoneNumber,
    this.customerName = "",
    required this.pincode,
    required this.deliveryBoyName,
    required this.deliveryBoyPhone,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {

    return OrderModel(

      orderId: json['orderId'] ?? 0,

      orderStatus: json['orderStatus'] ?? "",

      paymentStatus: json['paymentStatus'] ?? "",

      totalAmount:
      (json['totalAmount'] ?? 0).toDouble(),

      shippingAddress:
      json['shippingAddress'] ?? "",

      phoneNumber:
      json['phoneNumber'] ?? "",

      customerName:
      json['customerName'] ?? "",

      pincode:
      json['pincode'] ?? "",

      // 🚚 Delivery Boy Details
      deliveryBoyName:
      json['deliveryBoyName'] ?? "",

      deliveryBoyPhone:
      json['deliveryBoyPhone'] ?? "",

      createdAt: _parseDateTime(json['createdAt']),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItemModel.fromJson(e))
          .toList(),
    );
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw == null) return DateTime.now();
    final str = raw.toString();
    if (str.contains('Z') || str.contains('+') || (str.length > 19 && str.substring(19).contains('-'))) {
      return DateTime.parse(str).toLocal();
    }
    return DateTime.parse('${str}Z').toLocal();
  }
}