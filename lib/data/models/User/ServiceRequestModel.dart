import 'dart:convert';
import 'package:intl/intl.dart';

// -----------------------------------------------------------------------------
// Modelo para el Usuario (Cliente)
// -----------------------------------------------------------------------------
class UserModel {
  final int id;
  final String name;
  final String email;
  final String userType;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Cliente Desconocido',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'user_type': userType,
    };
  }
}

// -----------------------------------------------------------------------------
// Modelo para el Técnico
// -----------------------------------------------------------------------------
class TechnicianModel {
  final int id;
  final String name;
  final String email;
  final TechnicianProfile? profile;

  TechnicianModel({
    required this.id,
    required this.name,
    required this.email,
    this.profile,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Técnico',
      email: json['email'] ?? '',
      profile: json['technician_profile'] != null
          ? TechnicianProfile.fromJson(json['technician_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'technician_profile': profile?.toJson(),
    };
  }
}

class TechnicianProfile {
  final int userId;
  final String status;
  final double? currentLat;
  final double? currentLng;
  final double? averageRating;
  final String? vehicleDetails;
  final List<String>? availableConnectors;

  TechnicianProfile({
    required this.userId,
    required this.status,
    this.currentLat,
    this.currentLng,
    this.averageRating,
    this.vehicleDetails,
    this.availableConnectors,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    List<String>? connectors;
    if (json['available_connectors'] != null) {
      try {
        final connectorsData = json['available_connectors'];
        if (connectorsData is String) {
          final parsed = jsonDecode(connectorsData);
          connectors = List<String>.from(parsed);
        } else if (connectorsData is List) {
          connectors = List<String>.from(connectorsData);
        }
      } catch (e) {
        print('Error parsing available_connectors: $e');
      }
    }

    return TechnicianProfile(
      userId: json['user_id'] ?? 0,
      status: json['status'] ?? 'offline',
      currentLat: json['current_lat'] != null
          ? double.parse(json['current_lat'].toString())
          : null,
      currentLng: json['current_lng'] != null
          ? double.parse(json['current_lng'].toString())
          : null,
      averageRating: json['average_rating'] != null
          ? double.parse(json['average_rating'].toString())
          : null,
      vehicleDetails: json['vehicle_details'],
      availableConnectors: connectors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'average_rating': averageRating,
      'vehicle_details': vehicleDetails,
      'available_connectors': availableConnectors,
    };
  }
}

// ✅ CORRECCIONES PARA ServiceRequestModel
class ServiceRequestModel {
  final int id;
  final int userId;
  final int? technicianId;
  final String status;
  final double requestLat;
  final double requestLng;
  final double? estimatedCost;
  final double? finalCost;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final UserModel? user;
  final TechnicianModel? technician;

  // ✅ NUEVAS PROPIEDADES para la UI del técnico
  final String? clientName;
  final String? formattedDistance;
  final String? formattedEarnings;

  ServiceRequestModel({
    required this.id,
    required this.userId,
    this.technicianId,
    required this.status,
    required this.requestLat,
    required this.requestLng,
    this.estimatedCost,
    this.finalCost,
    required this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.user,
    this.technician,
    // ✅ NUEVOS parámetros opcionales
    this.clientName,
    this.formattedDistance,
    this.formattedEarnings,
  });

  // ✅ GETTERS calculados para retrocompatibilidad
  String get clientNameDisplay => clientName ?? user?.name ?? 'Cliente';
  String get formattedDistanceDisplay => formattedDistance ?? '0 km';
  String get formattedEarningsDisplay =>
      formattedEarnings ?? '\$${(estimatedCost ?? 5.0).toStringAsFixed(2)}';

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'],
      userId: json['user_id'],
      technicianId: json['technician_id'],
      status: json['status'],
      requestLat: double.parse(json['request_lat'].toString()),
      requestLng: double.parse(json['request_lng'].toString()),
      estimatedCost: json['estimated_cost'] != null
          ? double.parse(json['estimated_cost'].toString())
          : null,
      finalCost: json['final_cost'] != null
          ? double.parse(json['final_cost'].toString())
          : null,
      requestedAt: DateTime.parse(json['requested_at']),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      technician: json['technician'] != null
          ? TechnicianModel.fromJson(json['technician'])
          : null,
      // ✅ MANEJAR propiedades del técnico desde respuestas de check-for-requests
      clientName: json['user_name'],
      formattedDistance: json['distance'],
      formattedEarnings: json['base_cost'] != null
          ? '\$${double.parse(json['base_cost'].toString()).toStringAsFixed(2)}'
          : null,
    );
  } // ✅ NUEVO MÉTODO: Para verificar si el chat está disponible
  bool canChat() {
    // Solo puede chatear cuando el servicio está activo (aceptado hasta completado)
    return ['accepted', 'en_route', 'on_site', 'charging'].contains(status);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'technician_id': technicianId,
      'status': status,
      'request_lat': requestLat,
      'request_lng': requestLng,
      'estimated_cost': estimatedCost,
      'final_cost': finalCost,
      'requested_at': requestedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'user': user?.toJson(),
      'technician': technician?.toJson(),
    };
  }

  // ✅ MÉTODO para crear copia con nuevas propiedades
  ServiceRequestModel copyWith({
    int? id,
    int? userId,
    int? technicianId,
    String? status,
    double? requestLat,
    double? requestLng,
    double? estimatedCost,
    double? finalCost,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    UserModel? user,
    TechnicianModel? technician,
    String? clientName,
    String? formattedDistance,
    String? formattedEarnings,
  }) {
    return ServiceRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      technicianId: technicianId ?? this.technicianId,
      status: status ?? this.status,
      requestLat: requestLat ?? this.requestLat,
      requestLng: requestLng ?? this.requestLng,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      finalCost: finalCost ?? this.finalCost,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      user: user ?? this.user,
      technician: technician ?? this.technician,
      clientName: clientName ?? this.clientName,
      formattedDistance: formattedDistance ?? this.formattedDistance,
      formattedEarnings: formattedEarnings ?? this.formattedEarnings,
    );
  }

  // --- Helpers para formatear ---
  String get formattedTime {
    return DateFormat('h:mm a', 'es_ES').format(requestedAt);
  }

  String get formattedDate {
    return DateFormat('EEEE, d \'de\' MMMM', 'es_ES').format(requestedAt);
  }

  // ✅ GETTERS que evitan conflictos con las propiedades
  double get distanceKm {
    // Calcular distancia si es necesario o usar un valor por defecto
    return 0.0;
  }

  double get estimatedEarnings {
    return estimatedCost ?? 5.0;
  }
}
