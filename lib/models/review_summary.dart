import 'review.dart';

class ReviewSummary {
  final double averageRating;

  final int reviewCount;

  final int fiveStar;

  final int fourStar;

  final int threeStar;

  final int twoStar;

  final int oneStar;

  final List<Review> reviews;

  ReviewSummary({
    required this.averageRating,
    required this.reviewCount,
    required this.fiveStar,
    required this.fourStar,
    required this.threeStar,
    required this.twoStar,
    required this.oneStar,
    required this.reviews,
  });

  factory ReviewSummary.fromJson(
      Map<String, dynamic> json) {

    return ReviewSummary(

      averageRating:
      (json["averageRating"] as num?)
          ?.toDouble() ??
          0.0,

      reviewCount:
      json["reviewCount"] ?? 0,

      fiveStar:
      json["fiveStar"] ?? 0,

      fourStar:
      json["fourStar"] ?? 0,

      threeStar:
      json["threeStar"] ?? 0,

      twoStar:
      json["twoStar"] ?? 0,

      oneStar:
      json["oneStar"] ?? 0,

      reviews:
      (json["reviews"] as List<dynamic>?)

          ?.map(
            (e) => Review.fromJson(e),
      )

          .toList() ??

          [],
    );
  }
}