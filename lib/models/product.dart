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

  // =========================================
  // LIVE & COMING SOON STATUS
  // =========================================

  bool get isLive {
    final n = name.trim().toLowerCase();

    // Explicit exclusions for compound / liquid / non-live variants
    if (n.contains('compound')) return false;
    if (n.contains('detergent powder') || n.contains('detergent')) return false;
    if (n.contains('safe wash')) return false;
    if (n.contains('dish wash liquid') || n.contains('dish wash soap')) return false;
    if (n.contains('anti stain') || n.contains('antistain')) return false;
    if (n.contains('room freshener')) return false;
    if (n.contains('pet shampoo')) return false;

    // 1. Tiles Cleaner
    if (n.contains('tiles cleaner') || n.contains('tile cleaner') || n.contains('tiles+toiletcleaner')) return true;
    // 2. Toilet Cleaner
    if (n.contains('toilet cleaner') || n.contains('toiletcleaner')) return true;
    // 3. Glass Cleaner
    if (n.contains('glass cleaner') || n.contains('glasscleaner')) return true;
    // 4. Germtral / Germdral
    if (n.contains('germtral') || n.contains('germdral')) return true;
    // 5. White Phenyl
    if (n.contains('white phenyl') || n.contains('whitephenyl')) return true;
    // 6. Hand Wash Gel / Hand Wash
    if (n.contains('hand wash') || n.contains('handwash')) return true;
    // 7. Pink Phenyl
    if (n.contains('pink phenyl') || n.contains('pinkphenyl')) return true;
    // 8. Black Phenyl
    if (n.contains('black phenyl') || n.contains('blackphenyl')) return true;
    // 9. Dish Wash Gel
    if (n.contains('dish wash gel') || n.contains('dishwash gel')) return true;
    // 10. VehiClean / Car Shampoo
    if (n.contains('vehiclean') || n.contains('car shampoo') || n.contains('carshampoo')) return true;

    return false;
  }

  bool get isComingSoon => !isLive;
}