
// 3. Servicio actualizado para usar tu RatingController de Laravel
import 'package:Voltgo_app/data/models/TechnicianReview.dart';
import 'package:Voltgo_app/data/models/User/RatingSummary.dart';
import 'package:Voltgo_app/data/services/RatingService.dart';
import 'package:Voltgo_app/data/services/TechnicianService.dart';

class ReviewsService {
  static Future<RatingSummary?> getTechnicianReviews({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Usar tu método existente getRatingSummary
      final summaryData = await RatingService.getRatingSummary();
      if (summaryData == null) return null;

      // Tu controller ya devuelve el formato correcto para técnicos
      if (summaryData['user_type'] == 'technician') {
        final stats = summaryData['stats'];
        final recentRatings = summaryData['recent_ratings'];
        
        return RatingSummary(
          averageRating: stats['average_rating']?.toDouble() ?? 0.0,
          totalReviews: stats['total_ratings'] ?? 0,
          ratingDistribution: Map<int, int>.from({
            5: stats['rating_distribution']['5'] ?? 0,
            4: stats['rating_distribution']['4'] ?? 0,
            3: stats['rating_distribution']['3'] ?? 0,
            2: stats['rating_distribution']['2'] ?? 0,
            1: stats['rating_distribution']['1'] ?? 0,
          }),
          recentReviews: (recentRatings as List?)?.map((review) => 
            TechnicianReview.fromJson({
              'id': review['id'],
              'service_id': review['service_request_id'],
              'client_name': review['user']['name'],
              'rating': review['rating'],
              'comment': review['comment'],
              'created_at': review['created_at'],
              'service_type': 'Servicio de Carga',
              'vehicle_info': null, // Tu modelo actual no incluye esto
            })
          ).toList() ?? [],
        );
      }
      
      return null;
    } catch (e) {
      print('Error fetching reviews: $e');
      return null;
    }
  }

  static Future<List<TechnicianReview>> getAllReviews({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Primero necesitas obtener el ID del técnico actual
      final profile = await _getTechnicianProfile();
      if (profile == null) return [];
      
      final technicianId = profile['user']['id'];
      
      // Usar tu método getTechnicianRatings existente
      final ratingsData = await RatingService.getTechnicianRatings(
        technicianId, 
        page: page, 
        perPage: limit
      );
      
      if (ratingsData != null && ratingsData['ratings'] != null) {
        final ratingsResponse = ratingsData['ratings'];
        final reviews = ratingsResponse['data'] as List;
        
        return reviews.map((review) => 
          TechnicianReview.fromJson({
            'id': review['id'],
            'service_id': review['service_request_id'],
            'client_name': review['user']['name'],
            'rating': review['rating'],
            'comment': review['comment'],
            'created_at': review['created_at'],
            'service_type': 'Servicio de Carga',
            'vehicle_info': null, // Tu modelo actual no incluye esto
          })
        ).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching all reviews: $e');
      return [];
    }
  }

  // Método auxiliar para obtener el perfil del técnico
  static Future<Map<String, dynamic>?> _getTechnicianProfile() async {
    try {
      // Aquí usarías tu servicio existente para obtener el perfil
  return await TechnicianService.getProfile();
       
    } catch (e) {
      print('Error getting technician profile: $e');
      return null;
    }
  }
}
