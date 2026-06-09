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

  factory Product.fromJson(
      Map<String, dynamic> json) {

    return Product(

      id: json['id'],

      name: json['name'],

      description:
      json['description'] ?? '',

      price:
      (json['price'] as num)
          .toDouble(),

      costPrice:
      (json['costPrice'] as num?)
          ?.toDouble() ??
          0.0,

      stock: json['stock'],

      imageUrl:
      json['imageUrl'] ?? '',

      categoryId:
      json['categoryId'],

      categoryName:
      json['categoryName'] ?? '',

      // ⭐ NEW

      averageRating:
      (json['averageRating'] as num?)
          ?.toDouble() ??
          0.0,

      reviewCount:
      json['reviewCount'] ?? 0,
    );
  }
}