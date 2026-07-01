class Review {

  final int id;

  final String username;

  final int rating;

  final String comment;

  final DateTime createdAt;

  final DateTime? updatedAt;

  final bool verifiedPurchase;

  Review({

    required this.id,

    required this.username,

    required this.rating,

    required this.comment,

    required this.createdAt,

    required this.verifiedPurchase,

    this.updatedAt,
  });

  factory Review.fromJson(
      Map<String, dynamic> json) {

    return Review(

      id: json["id"],

      username: json["username"] ?? "",

      rating: json["rating"] ?? 0,

      comment: json["comment"] ?? "",

      createdAt: DateTime.parse(
        json["createdAt"],
      ),

      updatedAt: json["updatedAt"] == null

          ? null

          : DateTime.parse(
        json["updatedAt"],
      ),

      verifiedPurchase:
      json["verifiedPurchase"] ?? false,
    );
  }
}