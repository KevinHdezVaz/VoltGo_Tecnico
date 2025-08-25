// ✅ ChatMessage.dart - VERSIÓN CORREGIDA CON DEBUG

class ChatMessage {
  final int id;
  final int serviceRequestId;
  final int senderId;
  final String message;
  final DateTime createdAt;
  final ChatSender? sender;

  ChatMessage({
    required this.id,
    required this.serviceRequestId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ DEBUG: Imprimir la estructura del JSON
      print('🔍 Parsing ChatMessage JSON: $json');

      // ✅ CONVERSIÓN MUY SEGURA DE TODOS LOS IDs
      final parsedId = _parseToInt(json['id'], 'id');
      final parsedServiceRequestId =
          _parseToInt(json['service_request_id'], 'service_request_id');
      final parsedSenderId = _parseToInt(json['sender_id'], 'sender_id');

      print(
          '🔍 Parsed IDs - id: $parsedId, service_request_id: $parsedServiceRequestId, sender_id: $parsedSenderId');

      return ChatMessage(
        id: parsedId,
        serviceRequestId: parsedServiceRequestId,
        senderId: parsedSenderId,
        message: json['message']?.toString() ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        sender:
            json['sender'] != null ? ChatSender.fromJson(json['sender']) : null,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing ChatMessage: $e');
      print('📄 JSON data: $json');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ✅ MÉTODO HELPER PARA PARSEAR INTS SEGUROS
  static int _parseToInt(dynamic value, String fieldName) {
    if (value == null) {
      print('⚠️ Field $fieldName is null, using 0');
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        print('✅ Converted $fieldName from String "$value" to int $parsed');
        return parsed;
      } else {
        print('❌ Failed to parse $fieldName: "$value" is not a valid int');
        return 0;
      }
    }

    if (value is double) {
      print(
          '✅ Converted $fieldName from double $value to int ${value.toInt()}');
      return value.toInt();
    }

    print('❌ Unknown type for $fieldName: ${value.runtimeType}, value: $value');
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'sender': sender?.toJson(),
    };
  }

  // ✅ GETTER PARA TIEMPO FORMATEADO
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }
}

// ✅ ChatSender TAMBIÉN CORREGIDO
class ChatSender {
  final int id;
  final String name;
  final String? email;

  ChatSender({
    required this.id,
    required this.name,
    this.email,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing ChatSender JSON: $json');

      final parsedId = ChatMessage._parseToInt(json['id'], 'sender_id');

      return ChatSender(
        id: parsedId,
        name: json['name']?.toString() ?? 'Usuario',
        email: json['email']?.toString(),
      );
    } catch (e) {
      print('❌ Error parsing ChatSender: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
