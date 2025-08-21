import 'package:Voltgo_app/data/models/User/user_model.dart';

class LoginRequest {
  final String email; // Debe llamarse 'email'
  final String password;

  LoginRequest({
    required this.email, // Debe ser 'email'
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email, // La clave debe ser 'email' como un string
        'password': password,
      };
}

class LoginResponse {
  final String token;
  final String? error;

  LoginResponse({
    required this.token,
    this.error,
  });
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      error:
          json['message'], // Laravel usualmente devuelve el error en 'message'
    );
  }
}
