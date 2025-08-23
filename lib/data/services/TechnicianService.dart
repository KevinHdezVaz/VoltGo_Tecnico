import 'dart:convert';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianService {
  // Clave para guardar el estado en SharedPreferences
  static const String _statusKey = 'technician_status';

  // ✅ MÉTODO getCurrentStatus corregido
  static Future<String> getCurrentStatus() async {
    try {
      // Primero intentar obtener del backend
      final url = Uri.parse('${Constants.baseUrl}/technician/profile');
      final token = await TokenStorage.getToken();
      if (token == null) {
        print("❌ No hay token, obteniendo estado local");
        return await getLocalStatus();
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print("🌐 Obteniendo perfil del técnico desde: $url");
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 5));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📡 Perfil recibido: ${data.toString()}');

        final status = data['status'] ?? 'offline';
        await saveLocalStatus(status);
        print('✅ Estado obtenido del servidor: $status');
        return status;
      } else if (response.statusCode == 403) {
        print('❌ Usuario no es técnico');
        return 'offline';
      } else if (response.statusCode == 404) {
        print('❌ Perfil de técnico no encontrado');
        return 'offline';
      } else {
        print('❌ Error del servidor: ${response.body}');
        return await getLocalStatus();
      }
    } catch (e) {
      print('❌ Error obteniendo estado del servidor: $e');
      return await getLocalStatus();
    }
  }

  // ✅ MÉTODO getProfile actualizado
  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('${Constants.baseUrl}/technician/profile');
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    print("🌐 Obteniendo perfil completo del técnico");
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Perfil obtenido exitosamente');
        return data;
      } else if (response.statusCode == 403) {
        throw Exception('Usuario no autorizado - No es técnico');
      } else if (response.statusCode == 404) {
        print('⚠️ Perfil no encontrado, devolviendo perfil vacío');
        return {
          'status': 'offline',
          'vehicle_details': null,
          'average_rating': 5.0,
          'services_offered': [],
          'available_connectors': [],
        };
      } else {
        throw Exception('Error al cargar el perfil: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getProfile: $e');
      throw Exception('Error al cargar el perfil del técnico: $e');
    }
  }

  // ✅ MÉTODO updateVehicle
  static Future<void> updateVehicle(Map<String, dynamic> vehicleData) async {
    final url = Uri.parse('${Constants.baseUrl}/vehicles/update');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token de autenticación no encontrado');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode(vehicleData);
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el vehículo: ${response.body}');
    }
  }

  // ✅ MÉTODO registerVehicle
  static Future<void> registerVehicle(Map<String, dynamic> vehicleData) async {
    final url = Uri.parse('${Constants.baseUrl}/vehicles');
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('Token de autenticación no encontrado');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode(vehicleData);

    try {
      print('🌐 Enviando datos del vehículo a $url');
      final response = await http.post(url, headers: headers, body: body);
      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📡 Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Vehículo registrado exitosamente en el servidor.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Error al registrar el vehículo: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Excepción en registerVehicle: $e');
      throw Exception(
          'No se pudo conectar con el servidor. Inténtalo de nuevo.');
    }
  }

  // ✅ MÉTODOS de estado local
  static Future<void> saveLocalStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, status);
    print('💾 Estado guardado localmente: $status');
  }

  static Future<String> getLocalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_statusKey) ?? 'offline';
    print('📱 Estado obtenido localmente: $status');
    return status;
  }

  // ✅ MÉTODO checkForNewRequests actualizado
  static Future<List<Map<String, dynamic>>> checkForNewRequests() async {
    final url = Uri.parse('${Constants.baseUrl}/technician/check-for-requests');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🔄 Buscando nuevas solicitudes...');
      print('🌐 Haciendo request a: $url');

      final response = await http.get(url, headers: headers);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Solicitudes parseadas: ${data.length}');

        // ✅ VALIDAR y limpiar datos antes de retornar
        final validRequests = <Map<String, dynamic>>[];

        for (var item in data) {
          if (item is Map<String, dynamic> &&
              item['id'] != null &&
              item['status'] == 'pending') {
            // ✅ NORMALIZAR datos para consistencia
            final normalizedRequest = {
              'id': item['id'],
              'user_id': item['user_id'],
              'user_name': item['user_name'] ?? 'Cliente',
              'status': item['status'],
              'request_lat': item['request_lat']?.toString() ?? '0',
              'request_lng': item['request_lng']?.toString() ?? '0',
              'estimated_cost': item['estimated_cost'],
              'base_cost': item['base_cost']?.toString() ?? '5.00',
              'distance': item['distance'] ?? '0 km',
              'requested_at': item['requested_at'],
              'offered_at': item['offered_at'],
              'created_at': item['created_at'],
              'updated_at': item['updated_at'],
            };

            validRequests.add(normalizedRequest);
          }
        }

        print('✅ Solicitudes válidas: ${validRequests.length}');
        return validRequests;
      } else if (response.statusCode == 204) {
        print('ℹ️ No hay solicitudes pendientes');
        return [];
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};
        throw Exception('Error al buscar solicitudes: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Error en checkForNewRequests: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO getRequestStatus mejorado
  static Future<ServiceRequestModel?> getRequestStatus(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/technician/request/$requestId/status');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print('❌ Token no encontrado');
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🌐 Verificando estado de solicitud: $url');
      final response = await http.get(url, headers: headers);

      print('📡 Status check response: ${response.statusCode}');
      print('📡 Status check body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ServiceRequestModel.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        print(
            '⚠️ No autorizado - solicitud ya no disponible para este técnico');
        return null; // Retornar null sin lanzar excepción
      } else if (response.statusCode == 404) {
        print('⚠️ Solicitud no encontrada');
        return null;
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};
        throw Exception('Error al obtener estado: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Error en getRequestStatus: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO getOfferDetails
  static Future<Map<String, dynamic>?> getOfferDetails(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/technician/offer/$requestId/details');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🌐 Obteniendo detalles de oferta: $url');
      final response = await http.get(url, headers: headers);

      print('📡 Offer details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        print('⚠️ No tienes una oferta para esta solicitud');
        return null;
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};
        throw Exception(
            'Error al obtener detalles de oferta: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Error en getOfferDetails: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO acceptRequest mejorado
  static Future<bool> acceptRequest(int requestId) async {
    final url = Uri.parse('${Constants.baseUrl}/technician/$requestId/accept');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🚀 Aceptando solicitud: $requestId');
      final response = await http.post(url, headers: headers);

      print('📡 Accept response: ${response.statusCode}');
      print('📡 Accept body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Solicitud aceptada exitosamente');
        return true;
      } else if (response.statusCode == 409) {
        print('⚠️ Conflicto: La solicitud ya no está disponible');
        throw Exception('Esta solicitud ya fue tomada por otro técnico');
      } else if (response.statusCode == 403) {
        print('⚠️ No autorizado para aceptar esta solicitud');
        throw Exception('No tienes autorización para aceptar esta solicitud');
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};
        print('❌ Error del servidor: ${errorData['message']}');
        throw Exception('Error al aceptar solicitud: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Error en acceptRequest: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO rejectRequest mejorado
  static Future<bool> rejectRequest(int requestId) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/technician/request/$requestId/reject-offer');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🚀 Rechazando solicitud: $requestId');
      final response = await http.post(url, headers: headers);

      print('📡 Reject response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Solicitud rechazada exitosamente');
        return true;
      } else if (response.statusCode == 404) {
        print('⚠️ Oferta no encontrada - puede que ya haya expirado');
        return true; // Considerar como éxito si ya no existe
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};
        print('❌ Error del servidor: ${errorData['message']}');
        throw Exception('Error al rechazar solicitud: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Error en rejectRequest: $e');
      rethrow;
    }
  }

// ✅ NUEVO: Obtener servicio activo del técnico
  static Future<Map<String, dynamic>?> getActiveService() async {
    final url = Uri.parse('${Constants.baseUrl}/technician/active-service');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print('❌ Token no encontrado para getActiveService');
      return {'has_active_service': false};
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🌐 Obteniendo servicio activo: $url');
      final response = await http.get(url, headers: headers);

      print('📡 Active service response: ${response.statusCode}');
      print('📡 Active service body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Servicio activo encontrado');
        return data;
      } else if (response.statusCode == 404) {
        print('ℹ️ No hay servicio activo');
        return {'has_active_service': false};
      } else {
        print('❌ Error getting active service: ${response.statusCode}');
        return {'has_active_service': false};
      }
    } catch (e) {
      print('❌ Exception getting active service: $e');
      return {'has_active_service': false};
    }
  }

  // ✅ MÉTODO updateLocation
  static Future<void> updateLocation(double latitude, double longitude) async {
    final url = Uri.parse('${Constants.baseUrl}/technician/location');
    final token = await TokenStorage.getToken();
    if (token == null) return;

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Ubicación actualizada: ($latitude, $longitude)');
      } else {
        print('Fallo al actualizar ubicación: ${response.body}');
      }
    } catch (e) {
      print('Error de red al enviar ubicación: $e');
    }
  }

  // ✅ MÉTODO updateStatus
  static Future<void> updateStatus(String status) async {
    final url = Uri.parse('${Constants.baseUrl}/technician/status');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Authentication token not found');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({'status': status});
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to update status: ${response.body}');
    }

    // Guardar el estado localmente después de actualizar en el servidor
    await saveLocalStatus(status);
    print('Technician status updated to: $status');
  }
}
