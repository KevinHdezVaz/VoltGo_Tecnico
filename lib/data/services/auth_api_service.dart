import 'dart:convert';
import 'dart:io';
import 'package:Voltgo_app/data/models/LOGIN/login_request_model.dart';
import 'package:Voltgo_app/data/models/User/UserModel.dart';
import 'package:http/http.dart' as http;
import 'package:Voltgo_app/data/models/LOGIN/ResetPasswordModel.dart';
import 'package:Voltgo_app/data/models/LOGIN/logout_response.dart';
import 'package:Voltgo_app/data/services/UserCacheService.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';
import 'dart:developer' as developer;

class AuthService {
  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/login');
    final body = LoginRequest(email: email, password: password).toJson();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      developer.log('Respuesta de Login - Status: ${response.statusCode}');
      developer.log('Cuerpo de Login: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final token = jsonResponse['token'] as String?;

        if (token != null && token.isNotEmpty) {
          await TokenStorage.saveToken(token);
          developer.log('✅ Token guardado exitosamente: $token');
          return LoginResult(success: true);
        } else {
          developer.log(
              '❌ Error: El servidor respondió OK pero no se encontró el token.');
          return LoginResult(
              success: false, error: 'No se recibió el token del servidor.');
        }
      } else {
        String errorMessage = 'Credenciales inválidas.';
        try {
          final jsonResponse = jsonDecode(response.body);
          errorMessage = jsonResponse['message'] ?? errorMessage;
        } catch (e) {
          /* Mantener el mensaje por defecto */
        }

        developer.log('❌ Error de login: $errorMessage');
        return LoginResult(success: false, error: errorMessage);
      }
    } catch (e) {
      developer.log('❌ Excepción en login: $e');
      return LoginResult(
          success: false, error: 'Error de conexión con el servidor.');
    }
  }

  static Future<bool> hasRegisteredVehicle() async {
    final url = Uri.parse('${Constants.baseUrl}/profile');
    final token = await TokenStorage.getToken();

    if (token == null) {
      developer
          .log("❌ Token no encontrado. No se puede verificar el vehículo.");
      return false;
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hasVehicle = data['has_registered_vehicle'] == 1;
        developer.log('✅ Verificación de vehículo: $hasVehicle');
        return hasVehicle;
      } else {
        developer.log('❌ Error al verificar vehículo: ${response.body}');
        return false;
      }
    } catch (e) {
      developer.log('❌ Excepción al verificar vehículo: $e');
      return false;
    }
  }

  static Future<UserModel?> fetchUserProfile() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      developer.log('No hay token, no se puede obtener el perfil.');
      return null;
    }

    final url = Uri.parse('${Constants.baseUrl}/user/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        developer.log('✅ Perfil de usuario obtenido exitosamente.');
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        developer.log(
            '❌ Falló la obtención del perfil (Status: ${response.statusCode})');
        developer.log('   Respuesta del servidor: ${response.body}');
        await TokenStorage.deleteToken();
        return null;
      }
    } catch (e) {
      developer.log('❌ Excepción al obtener el perfil: $e');
      return null;
    }
  }

  static Future<RegisterResponse> registerTechnician({
    required String name,
    required String email,
    required String password,
    String? licenseNumber,
    File? idDocument,
    required String phone,
    required String baseLocation,
    required List<String> servicesOffered,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/register');
    var request = http.MultipartRequest('POST', url);

    request.headers['Accept'] = 'application/json';
    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['phone'] = phone;
    request.fields['user_type'] = 'technician';
    request.fields['base_location'] = baseLocation;

    // ▼▼▼ LÍNEA INCORRECTA ELIMINADA ▼▼▼
    // request.fields['services_offered'] = jsonEncode(servicesOffered);

    // ▼▼▼ SOLUCIÓN: AÑADE CADA SERVICIO EN UN BUCLE ▼▼▼
    for (int i = 0; i < servicesOffered.length; i++) {
      request.fields['services_offered[$i]'] = servicesOffered[i];
    }

    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      // CORRECCIÓN DE NOMBRE DE CAMPO: debe coincidir con el backend
      request.fields['license_number'] = licenseNumber;
    }

    if (idDocument != null) {
      // CORRECCIÓN DE NOMBRE DE CAMPO: debe coincidir con el backend
      request.files.add(
        await http.MultipartFile.fromPath('id_document', idDocument.path),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return RegisterResponse.fromJson(jsonDecode(response.body));
      } else {
        // Esto te dará un error más claro en la consola
        developer.log('Error en el registro: ${response.body}');
        throw Exception('Error en el registro: ${response.body}');
      }
    } catch (e) {
      developer.log('❌ Excepción en registerTechnician: $e');
      // Devuelve el error para que la UI lo muestre
      return RegisterResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  static Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String userType,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/register');
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'user_type': userType,
      if (phone != null) 'phone': phone,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final token = jsonResponse['token'];
        if (token != null) {
          await TokenStorage.saveToken(token);
          developer.log('Token de registro guardado exitosamente.');
        }
        return RegisterResponse.fromJson(jsonResponse);
      } else {
        String errorMessage = 'Error en el registro.';
        try {
          final jsonResponse = jsonDecode(response.body);
          errorMessage = jsonResponse['errors']?.values?.first[0] ??
              jsonResponse['message'] ??
              errorMessage;
        } catch (e) {
          errorMessage = response.body;
        }
        return RegisterResponse(success: false, error: errorMessage);
      }
    } catch (e) {
      developer.log('❌ Excepción en registro: $e');
      return RegisterResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  static Future<void> logout() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData();
      developer.log('No hay token almacenado. Caché local limpiada.');
      return;
    }

    final url = Uri.parse('${Constants.baseUrl}/logout');
    developer.log('URL de logout: $url');

    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      developer.log('Excepción durante logout: $e');
    } finally {
      await TokenStorage.deleteToken();
      await UserCacheService.clearUserData();
      developer.log('Datos locales y token limpiados.');
    }
  }

  static Future<String?> getStoredToken() async {
    final token = await TokenStorage.getToken();
    developer.log('Obteniendo token almacenado: $token');
    return token;
  }

  static Future<bool> isLoggedIn() async {
    return await TokenStorage.hasToken();
  }

  static Future<PasswordResetResponse> requestPasswordReset(
      String email) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    developer.log('Solicitando reset de contraseña - URL: $url');

    try {
      final response = await http.get(url);
      developer.log('Respuesta recibida - Status Code: ${response.statusCode}');
      developer.log('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return PasswordResetResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Código enviado correctamente',
          );
        } catch (e) {
          developer.log('Error al parsear JSON: $e');
          return PasswordResetResponse(
            success: false,
            message: 'Error al procesar la respuesta del servidor',
          );
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Error desconocido';
        developer.log('Error en reset: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      developer.log('Excepción en requestPasswordReset: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  static Future<PasswordResetResponse> verifyMfaCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    final body = MfaVerification(email: email, code: code).toJson();
    developer.log('Validando MFA - URL: $url');
    developer.log('Cuerpo de la solicitud: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      developer.log('Respuesta recibida - Status Code: ${response.statusCode}');
      developer.log('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          developer.log('Validación MFA exitosa');
          return PasswordResetResponse(
            success: true,
            message:
                jsonResponse['message'] ?? 'Código verificado correctamente',
          );
        } catch (e) {
          developer.log('Error al parsear JSON: $e');
          return PasswordResetResponse(
            success: false,
            message: 'Error al procesar la respuesta del servidor',
          );
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Código inválido';
        developer.log('Error en MFA: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      developer.log('Excepción en verifyMfaCode: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  static Future<PasswordResetResponse> setNewPassword({
    required String email,
    required String newPass,
    required String newPassCheck,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/user/reset-password/$email');
    final body = NewPasswordData(
      email: email,
      newPass: newPass,
      newPassCheck: newPassCheck,
    ).toJson();
    developer.log('Cambiando contraseña - URL: $url');
    developer.log('Cuerpo de la solicitud: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      developer.log('Respuesta recibida - Status Code: ${response.statusCode}');
      developer.log('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        developer.log('Cambio de contraseña exitoso');
        return PasswordResetResponse(
          success: true,
          message:
              jsonResponse['message'] ?? 'Contraseña cambiada correctamente',
        );
      } else {
        final jsonResponse = jsonDecode(response.body);
        final errorMsg =
            jsonResponse['message'] ?? 'Error al cambiar contraseña';
        developer.log('Error en setNewPassword: $errorMsg');
        return PasswordResetResponse(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      developer.log('Excepción en setNewPassword: $e');
      return PasswordResetResponse(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
}

class RegisterResponse {
  final bool success;
  final String? token;
  final UserModel? user;
  final String? error;

  RegisterResponse({
    required this.success,
    this.token,
    this.user,
    this.error,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: true,
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class LoginResult {
  final bool success;
  final String? error;

  LoginResult({required this.success, this.error});
}
