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
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Cliente Desconocido',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? 'user',
      phone: json['phone'] ?? 'phone',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'user_type': userType,
      'phone': phone,
    };
  }
}

// -----------------------------------------------------------------------------
// Modelo para VehicleDetails (NUEVA CLASE)
// -----------------------------------------------------------------------------
class VehicleDetails {
  final String make;
  final String model;
  final String year;
  final String connectorType;
  final String? plate;  // ✅ CAMBIAR: Opcional
  final String? color;  // ✅ CAMBIAR: Opcional

  VehicleDetails({
    required this.make,
    required this.model,
    required this.year,
    required this.connectorType,
    this.plate,  // ✅ CAMBIAR: Sin required
    this.color,  // ✅ CAMBIAR: Sin required
  });

factory VehicleDetails.fromJson(Map<String, dynamic> json) {
  print('=== PARSING VEHICLE DETAILS ===');
  print('Vehicle JSON: $json');
  print('Make: ${json['make']}');
  print('Model: ${json['model']}');
  print('Year: ${json['year']}');
  
  try {
    final vehicle = VehicleDetails(
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      connectorType: json['connector_type']?.toString() ?? '',
      plate: json['plate']?.toString(),
      color: json['color']?.toString(),
    );
    
    print('✅ VehicleDetails created successfully: ${vehicle.make} ${vehicle.model}');
    print('==============================');
    return vehicle;
    
  } catch (e) {
    print('❌ ERROR creating VehicleDetails: $e');
    print('==============================');
    rethrow;
  }
}

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'connector_type': connectorType,
      'plate': plate,
      'color': color,
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
  final VehicleDetails?
      vehicleDetails; // ✅ CORREGIDO: Cambiado de String? a VehicleDetails?
  final List<String>? availableConnectors;

  TechnicianProfile({
    required this.userId,
    required this.status,
    this.currentLat,
    this.currentLng,
    this.averageRating,
    this.vehicleDetails, // ✅ CORREGIDO
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
      // ✅ SOLUCIÓN: En TechnicianProfile.fromJson, cambiar esta línea:
      vehicleDetails: json['vehicle_details'] != null
          ? _parseVehicleDetails(json['vehicle_details'])
          : null,
      availableConnectors: connectors,
    );
  }

  static VehicleDetails? _parseVehicleDetails(dynamic vehicleData) {
    try {
      if (vehicleData is String) {
        // Si viene como string JSON, decodificar primero
        final decoded = jsonDecode(vehicleData);
        return VehicleDetails.fromJson(decoded);
      } else if (vehicleData is Map<String, dynamic>) {
        // Si ya viene como Map, usar directamente
        return VehicleDetails.fromJson(vehicleData);
      }
      return null;
    } catch (e) {
      print('Error parsing vehicle details: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'average_rating': averageRating,
      'vehicle_details': vehicleDetails?.toJson(), // ✅ CORREGIDO
      'available_connectors': availableConnectors,
    };
  }
}
// En ServiceRequestModel - agregar la propiedad clientVehicle

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

  // ✅ NUEVO: Vehículo del cliente
  final VehicleDetails? clientVehicle;

  // Propiedades para la UI del técnico
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
    this.clientVehicle, // ✅ NUEVO
    this.clientName,
    this.formattedDistance,
    this.formattedEarnings,
  });

  // ✅ GETTERS para información del vehículo
  String get clientVehicleInfo {
    if (clientVehicle != null) {
      return '${clientVehicle!.make} ${clientVehicle!.model} ${clientVehicle!.year}';
    }
    return 'Vehículo no especificado';
  }

  String get clientVehicleShort {
    if (clientVehicle != null) {
      return '${clientVehicle!.make} ${clientVehicle!.model}';
    }
    return 'N/A';
  }

  // Getters calculados para retrocompatibilidad
  String get clientNameDisplay => clientName ?? user?.name ?? 'Cliente';
  String get formattedDistanceDisplay => formattedDistance ?? '0 km';
  String get formattedEarningsDisplay =>
      formattedEarnings ?? '\$${(estimatedCost ?? 5.0).toStringAsFixed(2)}';

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
  print('🚗 VEHICLE_DEBUG: ServiceRequestModel parsing started');
  print('🚗 VEHICLE_DEBUG: client_vehicle exists: ${json['client_vehicle'] != null}');
  print('🚗 VEHICLE_DEBUG: client_vehicle raw: ${json['client_vehicle']}');

  VehicleDetails? parsedClientVehicle;
  
  try {
    if (json['client_vehicle'] != null) {
      print('🚗 VEHICLE_DEBUG: Attempting to parse client_vehicle...');
      parsedClientVehicle = VehicleDetails.fromJson(json['client_vehicle']);
      print('🚗 VEHICLE_DEBUG: ServiceRequestModel - Vehicle parsed: ${parsedClientVehicle.make} ${parsedClientVehicle.model}');
    } else {
      print('🚗 VEHICLE_DEBUG: client_vehicle is null in JSON');
    }
  } catch (e) {
    print('🚗 VEHICLE_DEBUG: ERROR in ServiceRequestModel parsing: $e');
    parsedClientVehicle = null;
  }

  final serviceRequest = ServiceRequestModel(
    id: json['id'],
    userId: json['user_id'],
    technicianId: json['technician_id'] is String
        ? int.tryParse(json['technician_id'])
        : json['technician_id'],
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
    // ✅ USAR LA VARIABLE PARSEADA CON MANEJO DE ERRORES
    clientVehicle: parsedClientVehicle,
    clientName: json['user_name'],
    formattedDistance: json['distance'],
    formattedEarnings: json['base_cost'] != null
        ? '\$${double.parse(json['base_cost'].toString()).toStringAsFixed(2)}'
        : null,
  );

  // 🚗 AGREGAR ESTOS DEBUG:
  print('🚗 VEHICLE_DEBUG: ServiceRequestModel created - clientVehicle is null: ${serviceRequest.clientVehicle == null}');
  if (serviceRequest.clientVehicle != null) {
    print('🚗 VEHICLE_DEBUG: Final vehicle in model: ${serviceRequest.clientVehicle!.make} ${serviceRequest.clientVehicle!.model}');
  }

  return serviceRequest;
}

  // Método para verificar si el chat está disponible
  bool canChat() {
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
      'client_vehicle': clientVehicle?.toJson(), // ✅ NUEVO
    };
  }

  // Método para crear copia con nuevas propiedades
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
    VehicleDetails? clientVehicle, // ✅ NUEVO
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
      clientVehicle: clientVehicle ?? this.clientVehicle, // ✅ NUEVO
      clientName: clientName ?? this.clientName,
      formattedDistance: formattedDistance ?? this.formattedDistance,
      formattedEarnings: formattedEarnings ?? this.formattedEarnings,
    );
  }

  // Helpers para formatear
  String get formattedTime {
    return DateFormat('h:mm a', 'es_ES').format(requestedAt);
  }

  String get formattedDate {
    return DateFormat('EEEE, d \'de\' MMMM', 'es_ES').format(requestedAt);
  }

  double get distanceKm => 0.0;
  double get estimatedEarnings => estimatedCost ?? 5.0;
}