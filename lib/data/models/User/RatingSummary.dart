
// 2. Modelo para el resumen de calificaciones
import 'package:Voltgo_app/data/models/TechnicianReview.dart';

class RatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // star -> count
  final List<TechnicianReview> recentReviews;

  RatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      averageRating: double.parse(json['average_rating'].toString()),
      totalReviews: json['total_reviews'],
      ratingDistribution: Map<int, int>.from(json['rating_distribution'] ?? {}),
      recentReviews: (json['recent_reviews'] as List?)
          ?.map((review) => TechnicianReview.fromJson(review))
          .toList() ?? [],
    );
  }

  double getPercentageForRating(int stars) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[stars] ?? 0;
    return (count / totalReviews) * 100;
  }
}
