import 'dart:convert';

import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:http/http.dart' as http;

class ServiceRequestService {
  /// Crea una nueva solicitud de servicio en el backend.
  static Future<ServiceRequestModel> createRequest(LatLng location) async {
    final url = Uri.parse('${Constants.baseUrl}/service/request');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'request_lat': location.latitude,
      'request_lng': location.longitude,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201) {
      return ServiceRequestModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al crear la solicitud: ${response.body}');
    }
  }

  // ✅ CORREGIDO: getRequestStatus usando la ruta correcta
  static Future<ServiceRequestModel> getRequestStatus(int requestId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$requestId/status');
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      print('🚀 Getting status for request: $requestId');
      final response = await http.get(url, headers: headers);

      print('📡 Get status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ServiceRequestModel.fromJson(jsonData);
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Error al obtener estado'};
        throw Exception(
            errorData['message'] ?? 'Error al obtener estado de la solicitud');
      }
    } catch (e) {
      print('❌ Error in getRequestStatus: $e');
      rethrow;
    }
  }
}
