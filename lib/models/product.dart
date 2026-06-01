class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double costPrice;   // 🔥 NEW
  final int stock;
  final String imageUrl;    // 🔥 NEW
  final int categoryId;     // 🔥 NEW
  final String categoryName; // 🔥 NEW

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'],
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? '',
    );
  }
}