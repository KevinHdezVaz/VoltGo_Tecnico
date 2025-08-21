import 'package:intl/intl.dart';

// -----------------------------------------------------------------------------
// Modelo para el Usuario (Cliente)
// -----------------------------------------------------------------------------
// Esta clase representa la información del cliente que viene anidada
// dentro de la solicitud de servicio.
class UserModel {
  final int id;
  final String name;
  // Puedes añadir más campos aquí en el futuro, como 'photo_url' o 'rating'.

  UserModel({
    required this.id,
    required this.name,
  });

  /// Constructor factory para crear un UserModel desde un mapa JSON.
  /// Es "seguro" porque maneja valores nulos.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Cliente Desconocido',
    );
  }
}

// -----------------------------------------------------------------------------
// Modelo para la Solicitud de Servicio
// -----------------------------------------------------------------------------
// Esta es la clase principal que representa un trabajo o servicio.
class ServiceRequestModel {
  final int id;
  final int? technicianId; // El ID del técnico (si está asignado)
  final UserModel? user; // Contiene los datos del cliente
  final String status;
  final double finalCost;
  final DateTime requestedAt;
  final String locationDescription;

  // --- CAMPOS NUEVOS Y CLAVE ---
  final double distanceKm; // Distancia calculada por el backend
  final double estimatedEarnings; // Ganancias calculadas por el backend

  ServiceRequestModel({
    required this.id,
    this.technicianId,
    this.user,
    required this.status,
    required this.finalCost,
    required this.requestedAt,
    required this.locationDescription,
    required this.distanceKm,
    required this.estimatedEarnings,
  });

  /// Constructor factory para crear un ServiceRequestModel desde un mapa JSON.
  /// Maneja de forma segura todos los posibles valores nulos de la API.
  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] ?? 0,
      technicianId: json['technician_id'],

      // Parsea el objeto 'user' anidado si existe
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,

      status: json['status'] ?? 'desconocido',
      finalCost: double.tryParse(json['final_cost'].toString()) ?? 0.0,

      // Parsea los nuevos campos calculados por el backend
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedEarnings:
          (json['estimated_earnings'] as num?)?.toDouble() ?? 0.0,

      requestedAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'])
          : DateTime.now(),

      locationDescription:
          "Asistencia en: ${json['request_lat'] ?? 'Ubicación no disponible'}",
    );
  }

  // --- Helpers para formatear la fecha y hora (no cambian) ---
  String get formattedTime {
    return DateFormat('h:mm a', 'es_ES').format(requestedAt);
  }

  String get formattedDate {
    return DateFormat('EEEE, d \'de\' MMMM', 'es_ES').format(requestedAt);
  }
}
