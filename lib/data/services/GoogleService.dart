import 'dart:convert';
import 'package:Voltgo_app/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

class GoogleAuthService {
  static const _storage = FlutterSecureStorage();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Configuración básica que funciona con las versiones específicas
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      developer.log('Iniciando Google Sign In...');
      
      // NO llamar signOut() para evitar errores
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return GoogleSignInResult(
          success: false,
          error: 'Usuario canceló el inicio de sesión',
        );
      }

      developer.log('Usuario: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final String? firebaseToken = await userCredential.user?.getIdToken();
      
      if (firebaseToken == null) {
        return GoogleSignInResult(
          success: false,
          error: 'Error con Firebase',
        );
      }

      final backendResult = await _sendTokenToBackend(firebaseToken);
      
      if (backendResult.success) {
        await _storage.write(key: 'auth_token', value: backendResult.token);
        return GoogleSignInResult(
          success: true,
          user: backendResult.user,
          token: backendResult.token,
        );
      } else {
        return GoogleSignInResult(
          success: false,
          error: backendResult.error ?? 'Error del servidor',
        );
      }

    } catch (e) {
      developer.log('Error: $e');
      return GoogleSignInResult(
        success: false,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  static Future<BackendAuthResult> _sendTokenToBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/auth/google-login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
          'app_type': 'technician', // ✅ ESPECIFICAR QUE ES APP DE TÉCNICOS
        }),
      );

      developer.log('Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return BackendAuthResult(
            success: true,
            user: data['user'],
            token: data['token'],
          );
        }
      }
      
      final data = jsonDecode(response.body);
      return BackendAuthResult(
        success: false,
        error: data['message'] ?? 'Error de autenticación',
      );
    } catch (e) {
      return BackendAuthResult(
        success: false,
        error: 'Error de conexión',
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _storage.delete(key: 'auth_token');
      await _googleSignIn.signOut();
    } catch (e) {
      developer.log('Error signOut: $e');
    }
  }

  static Future<bool> isSignedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }
}

class GoogleSignInResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? user;
  final String? token;
  final bool needsProfileCompletion;

  GoogleSignInResult({
    required this.success,
    this.error,
    this.user,
    this.token,
    this.needsProfileCompletion = false,
  });
}

class BackendAuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? user;
  final String? token;

  BackendAuthResult({
    required this.success,
    this.error,
    this.user,
    this.token,
  });
}