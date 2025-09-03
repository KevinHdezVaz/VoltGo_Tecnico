import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';

class EarningsService {
  /// Obtener resumen de ganancias (hoy, semana, mes)
  static Future<Map<String, dynamic>?> getEarningsSummary() async {
    final url = Uri.parse('${Constants.baseUrl}/technician/earnings/summary');
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
        print("✅ Resumen de ganancias obtenido");
        return data;
      } else {
        print("❌ Error obteniendo resumen: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getEarningsSummary: $e");
      return null;
    }
  }

  /// Obtener historial de ganancias con filtros
  static Future<List<dynamic>> getEarningsHistory({
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
  }) async {
    final queryParams = {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      'page': page.toString(),
      'per_page': '20',
    };

    final url = Uri.parse('${Constants.baseUrl}/technician/earnings/history')
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
        print("✅ Historial de ganancias obtenido");
        return data['data'] ?? [];
      } else {
        print("❌ Error obteniendo historial: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error en getEarningsHistory: $e");
      return [];
    }
  }

  /// Obtener detalle de una ganancia específica
  static Future<Map<String, dynamic>?> getEarningDetail(int earningId) async {
    final url =
        Uri.parse('${Constants.baseUrl}/technician/earnings/$earningId');
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
        print("✅ Detalle de ganancia obtenido");
        return data;
      } else {
        print("❌ Error obteniendo detalle: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error en getEarningDetail: $e");
      return null;
    }
  }

  /// Solicitar retiro de ganancias
  static Future<bool> requestWithdrawal(
      double amount, String paymentMethod) async {
    final url = Uri.parse('${Constants.baseUrl}/technician/earnings/withdraw');
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
      'amount': amount,
      'payment_method': paymentMethod,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("✅ Retiro procesado exitosamente");
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("❌ Error al solicitar retiro: ${error['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Error en requestWithdrawal: $e");
      return false;
    }
  }

  /// Agregar propina (para el cliente)
  static Future<bool> addTip(int serviceRequestId, double tipAmount) async {
    final url =
        Uri.parse('${Constants.baseUrl}/service/request/$serviceRequestId/tip');
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
      'tip_amount': tipAmount,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("✅ Propina agregada exitosamente");
        return true;
      } else {
        print("❌ Error al agregar propina: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error en addTip: $e");
      return false;
    }
  }
}
