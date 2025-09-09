import 'dart:convert';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';
import 'package:http/http.dart' as http; 

class RatingService {
  /// Enviar calificación para un servicio
  static Future<bool> submitRating(
    int serviceRequestId, 
    int rating, 
    String? comment
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/rating');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'rating': rating,
      'comment': comment,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("✅ Calificación enviada exitosamente");
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("❌ Error al enviar calificación: ${error['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Error en submitRating: $e");
      return false;
    }
  }

  /// Verificar si se puede calificar un servicio
  static Future<Map<String, dynamic>?> canRateService(int serviceRequestId) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/can-rate');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Verificación de rating obtenida");
        return data;
      } else {
        print("❌ Error verificando rating: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en canRateService: $e");
      return null;
    }
  }

  /// Obtener calificación de un servicio específico
  static Future<Map<String, dynamic>?> getRating(int serviceRequestId) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/rating');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Rating del servicio obtenido");
        return data;
      } else {
        print("❌ Error obteniendo rating: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getRating: $e");
      return null;
    }
  }

  /// Obtener calificaciones de un técnico específico
  static Future<Map<String, dynamic>?> getTechnicianRatings(
    int technicianId, {
    int page = 1,
    int perPage = 10
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final url = Uri.parse('${Constants.baseUrl}/technician/$technicianId/ratings')
        .replace(queryParameters: queryParams);

    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print("🔍 Obteniendo ratings para técnico $technicianId, página $page");
      final response = await http.get(url, headers: headers);

      print("🔍 Response status: ${response.statusCode}");
      print("🔍 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Ratings del técnico obtenidos: ${data.toString()}");
        return data;
      } else {
        print("❌ Error obteniendo ratings del técnico: ${response.statusCode}");
        print("❌ Error body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getTechnicianRatings: $e");
      return null;
    }
  }

  /// Obtener calificaciones del usuario
  static Future<List<dynamic>> getUserRatings({int page = 1}) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': '20',
    };

    final url = Uri.parse('${Constants.baseUrl}/user/ratings')
        .replace(queryParameters: queryParams);

    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return [];
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Ratings del usuario obtenidos");
        return data['data'] ?? [];
      } else {
        print("❌ Error obteniendo ratings del usuario: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error en getUserRatings: $e");
      return [];
    }
  }

  /// Eliminar una calificación
  static Future<bool> deleteRating(int ratingId) async {
    final url = Uri.parse('${Constants.baseUrl}/rating/$ratingId');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return false;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        print("✅ Calificación eliminada exitosamente");
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("❌ Error al eliminar calificación: ${error['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Error en deleteRating: $e");
      return false;
    }
  }

  /// Obtener resumen de calificaciones
  static Future<Map<String, dynamic>?> getRatingSummary() async {
    final url = Uri.parse('${Constants.baseUrl}/ratings/summary');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print("🔍 Obteniendo resumen de ratings...");
      final response = await http.get(url, headers: headers);

      print("🔍 Summary response status: ${response.statusCode}");
      print("🔍 Summary response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Resumen de ratings obtenido");
        return data;
      } else {
        print("❌ Error obteniendo resumen: ${response.statusCode}");
        print("❌ Error body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getRatingSummary: $e");
      return null;
    }
  }

  /// OPTIMIZADO: Obtener todas las calificaciones de un técnico con paginación extendida
  static Future<Map<String, dynamic>?> getAllTechnicianReviews({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print("🔍 getAllTechnicianReviews - Iniciando página $page, limit $limit");
      
      // Primero obtener el perfil del técnico para conseguir su ID
      final profileData = await _getTechnicianProfile();
      if (profileData == null) {
        print("❌ getAllTechnicianReviews - No se pudo obtener el perfil del técnico");
        return null;
      }

      print("🔍 getAllTechnicianReviews - Perfil obtenido: $profileData");
      final technicianId = profileData['user']['id'];
      print("🔍 getAllTechnicianReviews - ID del técnico: $technicianId");
      
      // Usar el método existente getTechnicianRatings con más elementos por página
      final ratingsData = await getTechnicianRatings(
        technicianId,
        page: page,
        perPage: limit,
      );

      print("🔍 getAllTechnicianReviews - Datos recibidos: $ratingsData");

      if (ratingsData != null) {
        // Reformatear la respuesta para que coincida con lo esperado por la UI
        final ratings = ratingsData['ratings'];
        final stats = ratingsData['stats'];
        
        print("🔍 getAllTechnicianReviews - Ratings data: $ratings");
        print("🔍 getAllTechnicianReviews - Stats data: $stats");
        
        final reviewsData = ratings['data'] ?? [];
        print("🔍 getAllTechnicianReviews - Reviews encontradas: ${reviewsData.length}");
        
        final result = {
          'reviews': reviewsData,
          'pagination': {
            'current_page': ratings['current_page'] ?? page,
            'per_page': ratings['per_page'] ?? limit,
            'total': ratings['total'] ?? 0,
            'total_pages': ((ratings['total'] ?? 0) / limit).ceil(),
            'has_more': (ratings['current_page'] ?? page) < ((ratings['total'] ?? 0) / limit).ceil(),
          },
          'stats': stats,
        };
        
        print("🔍 getAllTechnicianReviews - Resultado final: $result");
        return result;
      }

      print("❌ getAllTechnicianReviews - ratingsData es null");
      return null;
    } catch (e) {
      print("❌ Error en getAllTechnicianReviews: $e");
      print("❌ Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  /// OPTIMIZADO: Método auxiliar para obtener el perfil del técnico
  static Future<Map<String, dynamic>?> _getTechnicianProfile() async {
    final url = Uri.parse('${Constants.baseUrl}/technician/profile');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print("❌ _getTechnicianProfile - No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print("🔍 _getTechnicianProfile - Obteniendo perfil...");
      final response = await http.get(url, headers: headers);

      print("🔍 _getTechnicianProfile - Status: ${response.statusCode}");
      print("🔍 _getTechnicianProfile - Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Perfil del técnico obtenido");
        return data;
      } else {
        print("❌ Error obteniendo perfil del técnico: ${response.statusCode}");
        print("❌ Error body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error en _getTechnicianProfile: $e");
      return null;
    }
  }

  /// Obtener estadísticas específicas de calificaciones para dashboard
  static Future<Map<String, dynamic>?> getTechnicianStats() async {
    try {
      final summaryData = await getRatingSummary();
      
      if (summaryData != null && summaryData['user_type'] == 'technician') {
        return summaryData['stats'];
      }
      
      return null;
    } catch (e) {
      print("❌ Error en getTechnicianStats: $e");
      return null;
    }
  }

  /// Obtener reseñas recientes para vista rápida
  static Future<List<Map<String, dynamic>>> getRecentReviews({int limit = 5}) async {
    try {
      final summaryData = await getRatingSummary();
      
      if (summaryData != null && 
          summaryData['user_type'] == 'technician' && 
          summaryData['recent_ratings'] != null) {
        final recentRatings = summaryData['recent_ratings'] as List;
        return recentRatings.take(limit).cast<Map<String, dynamic>>().toList();
      }
      
      return [];
    } catch (e) {
      print("❌ Error en getRecentReviews: $e");
      return [];
    }
  }
}