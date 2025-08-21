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
}
