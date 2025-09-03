import 'dart:convert';
import 'dart:io';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';
import 'package:http_parser/http_parser.dart';
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

  static Future<bool> saveServiceDetails({
    required int serviceId,
    int? initialBatteryLevel,
    int? chargeTimeMinutes,
    String? serviceNotes,
    List<File>? photos,
    List<String>? photoTypes,
  }) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/technician/service/$serviceId/save-details');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    try {
      // Primero subir fotos si las hay
      bool photosUploaded = true;
      if (photos != null && photos.isNotEmpty && photoTypes != null) {
        photosUploaded = await uploadServicePhotos(
          serviceId: serviceId,
          photos: photos,
          photoTypes: photoTypes,
        );
      }

      if (!photosUploaded) {
        throw Exception('Error al subir fotos');
      }

      // Luego guardar los detalles del servicio
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'initial_battery_level': initialBatteryLevel,
        'charge_time_minutes': chargeTimeMinutes,
        'service_notes': serviceNotes,
        'service_completed_at': DateTime.now().toIso8601String(),
      });

      final response = await http.post(url, headers: headers, body: body);

      print('💾 Save details response: ${response.statusCode}');
      print('💾 Save details body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Detalles del servicio guardados exitosamente');
        return true;
      } else {
        throw Exception('Error del servidor: ${response.body}');
      }
    } catch (e) {
      print('❌ Error guardando detalles: $e');
      rethrow;
    }
  }

  static Future<bool> saveServiceProgress({
    required int serviceId,
    required bool serviceStarted,
    DateTime? serviceStartTime,
    String? initialBatteryLevel,
    String? chargeTimeMinutes,
    String? serviceNotes,
    List<String>? photosTaken,
  }) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/technician/service/$serviceId/save-progress');
    final token = await TokenStorage.getToken();

    if (token == null) return false;

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'service_started': serviceStarted,
      'service_start_time': serviceStartTime?.toIso8601String(),
      'initial_battery_level': initialBatteryLevel,
      'charge_time_minutes': chargeTimeMinutes,
      'service_notes': serviceNotes,
      'photos_taken': photosTaken ?? [],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      print('Error saving service progress: $e');
      return false;
    }
  }

  static Future<bool> uploadServicePhotos({
    required int serviceId,
    required List<File> photos,
    required List<String> photoTypes, // ['vehicle', 'before', 'after']
  }) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/technician/service/$serviceId/upload-photos');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Agregar fotos al request
      for (int i = 0; i < photos.length; i++) {
        var file = await http.MultipartFile.fromPath(
          '${photoTypes[i]}_photo',
          photos[i].path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📸 Upload photos response: ${response.statusCode}');
      print('📸 Upload photos body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error uploading photos: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getServiceProgress(int serviceId) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/technician/service/$serviceId/progress');
    final token = await TokenStorage.getToken();

    if (token == null) return null;

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🔍 Getting service progress for ID: $serviceId'); // ✅ AGREGAR
      final response = await http.get(url, headers: headers);
      print('📡 Progress response: ${response.statusCode}'); // ✅ AGREGAR
      print('📡 Progress body: ${response.body}'); // ✅ AGREGAR

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Progress data parsed: $data'); // ✅ AGREGAR
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting service progress: $e');
      return null;
    }
  }

  static Future<bool> forceReleaseExpiredService() async {
    final url =
        Uri.parse('${Constants.baseUrl}/technician/service/force-release');
    final token = await TokenStorage.getToken();

    if (token == null) return false;

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['cancelled'] == true;
      }
    } catch (e) {
      print('Error releasing expired service: $e');
    }

    return false;
  }

  static Future<Map<String, dynamic>?> checkServiceExpiration() async {
    final url =
        Uri.parse('${Constants.baseUrl}/technician/service/expiration-check');
    final token = await TokenStorage.getToken();

    if (token == null) {
      print('❌ Token no encontrado para checkServiceExpiration');
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🕐 Verificando expiración del servicio activo...');
      final response = await http.get(url, headers: headers);
      print('📡 Expiration check response: ${response.statusCode}');
      print('📡 Expiration check body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Datos de expiración obtenidos');
        return data;
      } else if (response.statusCode == 404) {
        print('ℹ️ No hay servicio activo para verificar expiración');
        return {'has_active_service': false};
      } else {
        print('❌ Error verificando expiración: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception en checkServiceExpiration: $e');
      return null;
    }
  }

  // ✅ NUEVO: Actualizar estado del servicio
  static Future<bool> updateServiceStatus(int serviceId, String status,
      {String? notes}) async {
    final url = Uri.parse(
        '${Constants.baseUrl}/technician/service/$serviceId/update-status');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'status': status,
      if (notes != null) 'notes': notes,
    });

    try {
      print('🔄 Actualizando estado del servicio a: $status');
      final response = await http.post(url, headers: headers, body: body);
      print('📡 Update status response: ${response.statusCode}');
      print('📡 Update status body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Estado del servicio actualizado exitosamente');
        return true;
      } else if (response.statusCode == 423) {
        final errorData = jsonDecode(response.body);
        throw Exception('Servicio expirado: ${errorData['message']}');
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};
        throw Exception('Error al actualizar estado: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Error en updateServiceStatus: $e');
      rethrow;
    }
  }

  // ✅ NUEVO: Cancelar servicio por el técnico
  static Future<Map<String, dynamic>> cancelService(
      int serviceId, String reason,
      {String? detailedReason}) async {
    final url =
        Uri.parse('${Constants.baseUrl}/technician/service/$serviceId/cancel');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'reason': reason,
      if (detailedReason != null) 'detailed_reason': detailedReason,
    });

    try {
      print('🚫 Cancelando servicio por técnico...');
      final response = await http.post(url, headers: headers, body: body);
      print('📡 Cancel service response: ${response.statusCode}');
      print('📡 Cancel service body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Servicio cancelado por técnico');
        return data;
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error desconocido'};
        throw Exception('Error al cancelar servicio: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Error en cancelService: $e');
      rethrow;
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
      print('🌐 Obteniendo servicio activo del técnico...');
      final response = await http.get(url, headers: headers);
      print('📡 Active service response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Servicio activo encontrado');

        // Agregar información de tiempo si hay servicio activo
        if (data['has_active_service'] == true &&
            data['active_service'] != null) {
          final service = data['active_service'];
          final acceptedAt = service['accepted_at'];

          if (acceptedAt != null) {
            final acceptedTime = DateTime.parse(acceptedAt);
            final now = DateTime.now();
            final minutesElapsed = now.difference(acceptedTime).inMinutes;

            data['time_info'] = {
              'minutes_elapsed': minutesElapsed,
              'hours_elapsed': (minutesElapsed / 60).floor(),
              'accepted_at': acceptedAt,
              'is_approaching_limit': minutesElapsed >= 45,
              'is_near_expiration': minutesElapsed >= 55,
              'expired': minutesElapsed >= 60,
            };
          }
        }

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
