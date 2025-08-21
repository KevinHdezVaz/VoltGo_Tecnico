import 'dart:convert';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianService {
  // Clave para guardar el estado en SharedPreferences
  static const String _statusKey = 'technician_status';

  // Obtener el estado actual del técnico desde el backend
  static Future<String> getCurrentStatus() async {
    try {
      // Primero intentar obtener del backend
      final url = Uri.parse('${Constants.baseUrl}/technician/profile');
      final token = await TokenStorage.getToken();

      if (token == null) {
        // Si no hay token, obtener el último estado guardado localmente
        return await getLocalStatus();
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['technician_profile']['status'] ?? 'offline';

        // Guardar el estado localmente
        await saveLocalStatus(status);

        print('✅ Estado obtenido del servidor: $status');
        return status;
      }
    } catch (e) {
      print('❌ Error obteniendo estado del servidor: $e');
    }

    // Si falla, obtener el estado guardado localmente
    return await getLocalStatus();
  }

  static Future<Map<String, dynamic>> getProfile() async {
    // Esta ruta ya la tienes definida en tu archivo de Laravel
    final url = Uri.parse('${Constants.baseUrl}/technician/profile');
    final token = await TokenStorage.getToken();

    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar el perfil del técnico');
    }
  }

  /// NUEVO: Actualiza los detalles del vehículo del técnico.
  static Future<void> updateVehicle(Map<String, dynamic> vehicleData) async {
    // Necesitaremos crear esta ruta en Laravel
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

  static Future<void> registerVehicle(Map<String, dynamic> vehicleData) async {
    // El endpoint debe coincidir con tu ruta en api.php, por ejemplo: Route::post('/vehicles', [VehicleController::class, 'store']);
    final url = Uri.parse('${Constants.baseUrl}/vehicles');
    final token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token de autenticación no encontrado');
    }

    final headers = {
      'Content-Type': 'application/json', // Importante para enviar datos JSON
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Codifica el mapa de datos a un string JSON
    final body = jsonEncode(vehicleData);

    try {
      print('🌐 Enviando datos del vehículo a $url');
      final response = await http.post(url, headers: headers, body: body);

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📡 Cuerpo de la respuesta: ${response.body}');

      // El controlador devuelve 201 (Created) si tiene éxito
      if (response.statusCode == 201) {
        print('✅ Vehículo registrado exitosamente en el servidor.');
      } else {
        // Si no, lanza un error con el mensaje del servidor
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Error al registrar el vehículo: ${errorData['message']}');
      }
    } catch (e) {
      print('❌ Excepción en registerVehicle: $e');
      // Re-lanza la excepción para que la UI pueda manejarla
      throw Exception(
          'No se pudo conectar con el servidor. Inténtalo de nuevo.');
    }
  }

  // Guardar el estado localmente
  static Future<void> saveLocalStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, status);
    print('💾 Estado guardado localmente: $status');
  }

  // Obtener el estado guardado localmente
  static Future<String> getLocalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_statusKey) ?? 'offline';
    print('📱 Estado obtenido localmente: $status');
    return status;
  }

  static Future<ServiceRequestModel?> checkForNewRequest() async {
    final url = Uri.parse('${Constants.baseUrl}/technician/check-for-requests');
    final token = await TokenStorage.getToken();
    if (token == null) {
      print("❌ No hay token disponible");
      return null;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    print("🌐 Haciendo request a: $url");

    try {
      final response = await http.get(url, headers: headers);
      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final request = ServiceRequestModel.fromJson(jsonDecode(response.body));
        print("✅ Solicitud parseada: ${request.id}");
        return request;
      } else if (response.statusCode == 204) {
        print("ℹ️ No content (204) - No hay solicitudes");
      } else {
        print("❌ Error en la respuesta: ${response.statusCode}");
      }

      return null;
    } catch (e) {
      print("❌ Error en checkForNewRequest: $e");
      return null;
    }
  }

  static Future<ServiceRequestModel> getRequestStatus(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/status');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return ServiceRequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener estado: ${response.body}');
    }
  }

  static Future<void> acceptRequest(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/accept');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Esta solicitud ya no está disponible');
    }
  }

  static Future<void> rejectRequest(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/reject');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🌐 Enviando solicitud de rechazo a: $url');
      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 5));
      print('📡 Rechazar solicitud - Código de estado: ${response.statusCode}');
      print('📡 Rechazar solicitud - Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Solicitud $requestId rechazada exitosamente');
        return;
      } else {
        throw Exception(
            'Error al rechazar la solicitud: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error al rechazar la solicitud $requestId: $e');
      throw Exception('Error al rechazar la solicitud: $e');
    }
  }

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
