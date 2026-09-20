class Product {

  final int id;

  final String name;

  final String description;

  final double price;

  final double costPrice;

  final int stock;

  final String imageUrl;

  final int categoryId;

  final String categoryName;

  // ⭐ NEW
  final double averageRating;

  final int reviewCount;

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

    required this.averageRating,

    required this.reviewCount,
  });

  factory Product.fromJson(Map<dynamic, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}