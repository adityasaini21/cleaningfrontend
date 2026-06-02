class Review {

  final int id;
  final String username;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.username,
    required this.rating,
    required this.comment,
    required this.createdAt,
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
    );
  }
}