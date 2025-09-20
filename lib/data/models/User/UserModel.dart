// This is the model for the user object returned by your API
class UserModel {
  final int id;
  final String name;
  final String email;
  final String userType;
  // This might be null for technicians, so we make it optional
  final bool? hasRegisteredVehicle;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.hasRegisteredVehicle,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'user',
      hasRegisteredVehicle: json['has_registered_vehicle'] == 1,
    );
  }

  // ✅ MÉTODO AGREGADO: toJson()
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'user_type': userType,
      'has_registered_vehicle': hasRegisteredVehicle == true ? 1 : 0,
    };
  }

  // ✅ MÉTODO ADICIONAL: toString() para debugging
  @override
  String toString() {
    return 'UserModel{id: $id, name: $name, email: $email, userType: $userType, hasRegisteredVehicle: $hasRegisteredVehicle}';
  }

  // ✅ MÉTODO ADICIONAL: copyWith() para crear copias con modificaciones
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? userType,
    bool? hasRegisteredVehicle,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      hasRegisteredVehicle: hasRegisteredVehicle ?? this.hasRegisteredVehicle,
    );
  }
}