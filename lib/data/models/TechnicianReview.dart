class TechnicianReview {
  final int id;
  final int serviceId;
  final String clientName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final String? serviceType;
  final String? vehicleInfo;

  TechnicianReview({
    required this.id,
    required this.serviceId,
    required this.clientName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.serviceType,
    this.vehicleInfo,
  });

  factory TechnicianReview.fromJson(Map<String, dynamic> json) {
    return TechnicianReview(
      id: json['id'],
      serviceId: json['service_id'],
      clientName: json['client_name'] ?? 'Cliente',
      rating: double.parse(json['rating'].toString()),
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      serviceType: json['service_type'],
      vehicleInfo: json['vehicle_info'],
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks semana${weeks > 1 ? 's' : ''}';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months mes${months > 1 ? 'es' : ''}';
    }
  }
}
