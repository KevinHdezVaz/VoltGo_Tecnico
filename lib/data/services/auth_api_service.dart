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

// ✅ NUEVAS IMPORTACIONES PARA GOOGLE SIGN IN
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // ✅ NUEVA CONFIGURACIÓN PARA GOOGLE SIGN IN
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // TU MÉTODO LOGIN EXISTENTE (sin cambios)
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



// Agrega este método a tu AuthService existente

static Future<RegisterResponse> updateTechnicianProfile({
  required String phone,
  required String baseLocation,
  required List<String> servicesOffered,
  String? licenseNumber,
  File? idDocument,
}) async {
  final url = Uri.parse('${Constants.baseUrl}/auth/update-technician-profile');
  final token = await TokenStorage.getToken();

  if (token == null) {
    return RegisterResponse(success: false, error: 'No hay token de autenticación');
  }

  var request = http.MultipartRequest('POST', url);

  request.headers['Accept'] = 'application/json';
  request.headers['Authorization'] = 'Bearer $token';
  
  request.fields['phone'] = phone;
  request.fields['base_location'] = baseLocation;

  // Agregar cada servicio por separado
  for (int i = 0; i < servicesOffered.length; i++) {
    request.fields['services_offered[$i]'] = servicesOffered[i];
  }

  if (licenseNumber != null && licenseNumber.isNotEmpty) {
    request.fields['license_number'] = licenseNumber;
  }

  if (idDocument != null) {
    request.files.add(
      await http.MultipartFile.fromPath('id_document', idDocument.path),
    );
  }

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    developer.log('Respuesta update profile - Status: ${response.statusCode}');
    developer.log('Cuerpo update profile: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        return RegisterResponse(
          success: true,
          user: jsonResponse['user'] != null 
              ? UserModel.fromJson(jsonResponse['user']) 
              : null,
        );
      } else {
        return RegisterResponse(
          success: false, 
          error: jsonResponse['message'] ?? 'Error actualizando perfil'
        );
      }
    } else {
      developer.log('Error en actualización de perfil: ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      return RegisterResponse(
        success: false, 
        error: jsonResponse['message'] ?? 'Error en el servidor'
      );
    }
  } catch (e) {
    developer.log('❌ Excepción en updateTechnicianProfile: $e');
    return RegisterResponse(success: false, error: 'Error de conexión: $e');
  }
}


// REEMPLAZA estos dos métodos en tu AuthService:

// ✅ CAMBIO 1: Método loginWithGoogle actualizado
static Future<GoogleSignInResult> loginWithGoogle() async {
  try {
    developer.log('🔍 Iniciando Google Sign In...');
    
    // 1. Cerrar sesión anterior si existe
    await _googleSignIn.signOut();
    
    // 2. Iniciar sesión con Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      developer.log('❌ Usuario canceló el inicio de sesión con Google');
      return GoogleSignInResult(
        success: false,
        error: 'El usuario canceló el inicio de sesión',
      );
    }

    developer.log('✅ Usuario de Google obtenido: ${googleUser.email}');

    // 3. Obtener detalles de autenticación
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 4. Crear credencial para Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 5. Iniciar sesión en Firebase
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    
    // 6. Obtener el ID Token de Firebase
    final String? idToken = await userCredential.user?.getIdToken();
    
    if (idToken == null) {
      developer.log('❌ No se pudo obtener el token de Firebase');
      return GoogleSignInResult(
        success: false,
        error: 'No se pudo obtener el token de Firebase',
      );
    }

    developer.log('✅ Token de Firebase obtenido');

    // 7. Enviar el token al backend
    final backendResult = await _sendTokenToBackend(idToken);
    
    if (backendResult.success) {
      developer.log('✅ Login con Google exitoso');
      return GoogleSignInResult(
        success: true,
        user: backendResult.user,
        token: backendResult.token,
      );
    } else {
      developer.log('❌ Error en backend: ${backendResult.error}');
      return GoogleSignInResult(
        success: false,
        error: backendResult.error ?? 'Error en el servidor',
      );
    }

  } catch (e) {
    developer.log('❌ Error en signInWithGoogle: $e');
    return GoogleSignInResult(
      success: false,
      error: 'Error inesperado: ${e.toString()}',
    );
  }
}

// ✅ CAMBIO 2: Método _sendTokenToBackend actualizado
static Future<GoogleSignInResult> _sendTokenToBackend(String idToken) async {
  try {
    final url = Uri.parse('${Constants.baseUrl}/auth/google-login');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_token': idToken,
        'app_type': 'technician', // Especificar que es app de técnicos
      }),
    );

    developer.log('Respuesta Google Backend - Status: ${response.statusCode}');
    developer.log('Cuerpo Google Backend: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['success'] == true) {
        final token = jsonResponse['token'] as String?;
        final user = jsonResponse['user'] as Map<String, dynamic>?;
        
        if (token != null && token.isNotEmpty) {
          await TokenStorage.saveToken(token);
          developer.log('✅ Token de Google guardado exitosamente');
          return GoogleSignInResult(
            success: true,
            user: user,
            token: token,
          );
        } else {
          return GoogleSignInResult(
            success: false,
            error: 'No se recibió el token del servidor',
          );
        }
      } else {
        return GoogleSignInResult(
          success: false,
          error: jsonResponse['message'] ?? 'Error en la autenticación',
        );
      }
    } else {
      String errorMessage = 'Error en la autenticación con Google';
      try {
        final jsonResponse = jsonDecode(response.body);
        errorMessage = jsonResponse['message'] ?? errorMessage;
      } catch (e) {
        /* Mantener el mensaje por defecto */
      }

      return GoogleSignInResult(success: false, error: errorMessage);
    }
  } catch (e) {
    developer.log('❌ Excepción enviando token al backend: $e');
    return GoogleSignInResult(
      success: false,
      error: 'Error de conexión con el servidor',
    );
  }
}


  // TODOS TUS MÉTODOS EXISTENTES (sin cambios)
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

    for (int i = 0; i < servicesOffered.length; i++) {
      request.fields['services_offered[$i]'] = servicesOffered[i];
    }

    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      request.fields['license_number'] = licenseNumber;
    }

    if (idDocument != null) {
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
        developer.log('Error en el registro: ${response.body}');
        throw Exception('Error en el registro: ${response.body}');
      }
    } catch (e) {
      developer.log('❌ Excepción en registerTechnician: $e');
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

  // ✅ MÉTODO LOGOUT ACTUALIZADO PARA INCLUIR GOOGLE
  static Future<void> logout() async {
    final token = await TokenStorage.getToken();
    
    // Cerrar sesión de Google y Firebase
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      developer.log('✅ Sesiones de Google y Firebase cerradas');
    } catch (e) {
      developer.log('❌ Error cerrando sesión de Google/Firebase: $e');
    }

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

  // ✅ MÉTODO PARA VERIFICAR SI ESTÁ LOGUEADO CON GOOGLE
  static Future<bool> isSignedInWithGoogle() async {
    final googleUser = await _googleSignIn.isSignedIn();
    final firebaseUser = _auth.currentUser;
    return googleUser && firebaseUser != null;
  }

  // RESTO DE TUS MÉTODOS EXISTENTES (sin cambios)
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

// Agrega esta clase al final de tu auth_api_service.dart

class GoogleSignInResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? user;
  final String? token;

  GoogleSignInResult({
    required this.success,
    this.error,
    this.user,
    this.token,
  });
}


// TUS CLASES EXISTENTES (sin cambios)
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