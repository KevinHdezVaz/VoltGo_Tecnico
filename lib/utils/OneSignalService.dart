import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Para detectar plataforma
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http; 
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/constants.dart';

// Logging siguiendo tu patrón
class Log {
  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final logMessage = '[ERROR] $tag: $message${error != null ? ' | Error: $error' : ''}${stackTrace != null ? '\nStackTrace: $stackTrace' : ''}';
    debugPrint(logMessage);
  }

  static void i(String tag, String message) {
    debugPrint('[INFO] $tag: $message');
  }

  static void d(String tag, String message) {
    debugPrint('[DEBUG] $tag: $message');
  }
}

// Eventos para comunicación entre widgets
class NewServiceRequestEvent {
  final int serviceRequestId;
  final String clientName;
  final Map<String, dynamic> additionalData;
  
  NewServiceRequestEvent(this.serviceRequestId, this.clientName, this.additionalData);
}

class ServiceCancelledEvent {
  final int serviceRequestId;
  final String reason;
  
  ServiceCancelledEvent(this.serviceRequestId, this.reason);
}

class ServiceStatusUpdateEvent {
  final int serviceRequestId;
  final String newStatus;
  final String? oldStatus;
  
  ServiceStatusUpdateEvent(this.serviceRequestId, this.newStatus, [this.oldStatus]);
}

class OneSignalService {
  static const String _tag = 'OneSignalService';
  static const String _oneSignalAppId = "3708fbd6-1d48-48aa-94dc-3fa8cbdcdd16";
  static const _storage = FlutterSecureStorage();
  
  // EventBus para comunicación
  static final EventBus eventBus = EventBus();
  
  // Estado del servicio
  static bool _isInitialized = false;
  static String? _playerId;
  static String? _currentUserId;
  // ✅ NUEVO: Guardar también el push token y device type
  static String? _pushToken;
  static String? _deviceType;

  /// Inicializar OneSignal
  static Future<void> initialize() async {
    if (_isInitialized) {
      Log.i(_tag, 'OneSignal already initialized');
      return;
    }

    try {
      Log.i(_tag, 'Starting OneSignal initialization');

      // ✅ NUEVO: Detectar tipo de dispositivo
      _deviceType = Platform.isIOS ? 'ios' : 'android';
      Log.d(_tag, 'Device type detected: $_deviceType');

      // Configurar OneSignal
      OneSignal.shared.setAppId(_oneSignalAppId);
      
      // Configurar logging en debug
      OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

      // Configurar handlers
      OneSignal.shared.setNotificationWillShowInForegroundHandler(_handleForegroundNotification);
      OneSignal.shared.setNotificationOpenedHandler(_handleNotificationOpened);
      OneSignal.shared.setSubscriptionObserver(_handleSubscriptionChanged);

      // ✅ NUEVO: Obtener push token si está disponible
      try {
        final deviceState = await OneSignal.shared.getDeviceState();
        if (deviceState != null) {
          _pushToken = deviceState.pushToken;
          Log.d(_tag, 'Push token obtained: ${_pushToken != null ? "✓" : "✗"}');
        }
      } catch (e) {
        Log.e(_tag, 'Error getting device state', e);
      }

      // Solicitar permisos
      final permissionGranted = await OneSignal.shared.promptUserForPushNotificationPermission();
      Log.i(_tag, 'Push notification permission: ${permissionGranted ? "Granted" : "Denied"}');

      _isInitialized = true;
      Log.i(_tag, 'OneSignal initialized successfully');

    } catch (e, stackTrace) {
      Log.e(_tag, 'Error initializing OneSignal', e, stackTrace);
      rethrow;
    }
  }

/// Manejar cambios en suscripción - CORREGIDO
static void _handleSubscriptionChanged(OSSubscriptionStateChanges changes) {
  Log.i(_tag, 'Subscription changed');
  Log.d(_tag, 'Previous user ID: ${changes.from.userId}');
  Log.d(_tag, 'New user ID: ${changes.to.userId}');
  Log.d(_tag, 'Is subscribed: ${changes.to.isSubscribed}');

  _playerId = changes.to.userId;
  
  // ✅ NUEVO: Registrar inmediatamente si ya tenemos usuario autenticado
  if (_playerId != null && _playerId!.isNotEmpty && _currentUserId != null) {
    Log.i(_tag, 'Player ID received, registering device immediately');
    _getPushTokenAndRegister();
  } else {
    Log.d(_tag, 'Waiting for authenticated user or player ID not ready yet');
  }
}


  /// ✅ NUEVO: Obtener push token y registrar dispositivo
  static Future<void> _getPushTokenAndRegister() async {
    try {
      final deviceState = await OneSignal.shared.getDeviceState();
      if (deviceState != null) {
        _pushToken = deviceState.pushToken;
        Log.d(_tag, 'Updated push token: ${_pushToken != null ? "Available" : "Not available"}');
        
        // Si tenemos playerId y usuario autenticado, registrar
        if (_playerId != null && _playerId!.isNotEmpty && _currentUserId != null) {
          await _registerDeviceInBackend(_playerId!);
        }
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error getting push token', e, stackTrace);
    }
  }

  /// Manejar notificaciones en primer plano
  static void _handleForegroundNotification(OSNotificationReceivedEvent event) {
    Log.i(_tag, 'Notification received in foreground');
    Log.d(_tag, 'Title: ${event.notification.title}');
    Log.d(_tag, 'Body: ${event.notification.body}');
    
    final data = event.notification.additionalData;
    if (data != null) {
      Log.d(_tag, 'Additional data: $data');
      _processNotificationData(data, isBackground: false);
    }

    // Mostrar la notificación en primer plano
    event.complete(event.notification);
  }

  /// Manejar cuando el usuario toca una notificación
  static void _handleNotificationOpened(OSNotificationOpenedResult result) {
    Log.i(_tag, 'Notification opened by user');
    Log.d(_tag, 'Title: ${result.notification.title}');
    Log.d(_tag, 'Body: ${result.notification.body}');
    
    final data = result.notification.additionalData;
    if (data != null) {
      Log.d(_tag, 'Processing notification data: $data');
      _processNotificationData(data, isBackground: true);
    }
  }

  /// Procesar datos de notificación
  static void _processNotificationData(Map<String, dynamic> data, {required bool isBackground}) {
    final type = data['type'];
    Log.d(_tag, 'Processing notification type: $type, from background: $isBackground');
    
    try {
      switch (type) {
        case 'new_service_request':
          _handleNewServiceRequest(data, isBackground);
          break;
        case 'service_cancelled':
          _handleServiceCancelled(data, isBackground);
          break;
        case 'service_status_update':
          _handleServiceStatusUpdate(data, isBackground);
          break;
        default:
          Log.e(_tag, 'Unknown notification type: $type');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error processing notification data', e, stackTrace);
    }
  }

  /// Manejar nueva solicitud de servicio
  static void _handleNewServiceRequest(Map<String, dynamic> data, bool isBackground) {
    final serviceRequestId = _parseIntFromData(data['service_request_id']);
    final clientName = data['client_name'] ?? 'Cliente';
    
    Log.i(_tag, 'New service request: $clientName (ID: $serviceRequestId)');
    
    eventBus.fire(NewServiceRequestEvent(serviceRequestId, clientName, data));
  }

  /// Manejar cancelación de servicio
  static void _handleServiceCancelled(Map<String, dynamic> data, bool isBackground) {
    final serviceRequestId = _parseIntFromData(data['service_request_id']);
    final reason = data['reason'] ?? 'cancelled';
    
    Log.i(_tag, 'Service cancelled: ID $serviceRequestId, reason: $reason');
    
    eventBus.fire(ServiceCancelledEvent(serviceRequestId, reason));
  }

  /// Manejar actualización de estado
  static void _handleServiceStatusUpdate(Map<String, dynamic> data, bool isBackground) {
    final serviceRequestId = _parseIntFromData(data['service_request_id']);
    final newStatus = data['new_status'] ?? '';
    final oldStatus = data['old_status'];
    
    Log.i(_tag, 'Service status update: ID $serviceRequestId -> $newStatus');
    
    eventBus.fire(ServiceStatusUpdateEvent(serviceRequestId, newStatus, oldStatus));
  }

  /// Parsear entero de datos
  static int _parseIntFromData(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
/// ✅ CORREGIDO: Registrar dispositivo en backend con todos los datos
  static Future<void> _registerDeviceInBackend(String playerId) async {
    Log.i(_tag, 'Registering device in backend');
    
    try {
      final token = await _getTokenWithValidation(); // Verify token retrieval
      final url = Uri.parse('${Constants.baseUrl}/onesignal/register-device');
      
      final headers = {
      'Authorization': 'Bearer $token', // CAMBIO: Bearer en lugar de Token
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode({
        'player_id': playerId, // This is the OneSignal User ID
        'device_type': _deviceType ?? 'android', // Ensure this is correctly set
        'device_token': _pushToken, // This is the FCM/APNS token, OneSignal also provides it
      });

      Log.d(_tag, 'Registering device - URL: $url');
      Log.d(_tag, 'Device data: player_id=$playerId, device_type=$_deviceType, push_token=$_pushToken'); // Log the data being sent

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      Log.i(_tag, 'Device registration response status: ${response.statusCode}');
      Log.d(_tag, 'Device registration response body: ${response.body}'); // Log the full response

      if (response.statusCode == 200) {
        Log.i(_tag, 'Device registered successfully: $playerId');
      } else {
        Log.e(_tag, 'Device registration failed: ${response.statusCode} - ${response.body}');
        // Consider throwing an exception here if registration is critical
      }

    } catch (e, stackTrace) {
      Log.e(_tag, 'Error registering device in backend', e, stackTrace);
    }
  }

  /// Actualizar estado de la app
  static Future<void> updateAppState(String state) async {
    Log.d(_tag, 'Updating app state to: $state');
    
    try {
      final token = await _getTokenWithValidation();
      final url = Uri.parse('${Constants.baseUrl}/technician/update-app-state');
      
      final headers = {
      'Authorization': 'Bearer $token', // CAMBIO: Bearer en lugar de Token
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode({
        'app_state': state,
      });

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Log.d(_tag, 'App state updated successfully: $state');
      } else {
        Log.e(_tag, 'App state update failed: ${response.statusCode}');
      }

    } catch (e, stackTrace) {
      Log.e(_tag, 'Error updating app state', e, stackTrace);
    }
  }


/// Configurar usuario autenticado - MODIFICADO
static Future<void> setAuthenticatedUser(String userId, String authToken) async {
  Log.i(_tag, 'Setting authenticated user: $userId');
  
  _currentUserId = userId;
  
  try {
    await _storage.write(key: 'auth_token', value: authToken);
    
    // Si ya tenemos playerId, registrar inmediatamente
    if (_playerId != null && _playerId!.isNotEmpty) {
      Log.i(_tag, 'Player ID already available, registering device');
      await _registerDeviceInBackend(_playerId!);
    } else {
      // ✅ NUEVO: Intentar obtener playerId actual
      Log.d(_tag, 'No player ID yet, checking current device state...');
      try {
        final deviceState = await OneSignal.shared.getDeviceState();
        if (deviceState != null && deviceState.userId != null) {
          _playerId = deviceState.userId;
          _pushToken = deviceState.pushToken;
          
          Log.i(_tag, 'Found existing player ID: $_playerId');
          await _registerDeviceInBackend(_playerId!);
        } else {
          Log.d(_tag, 'No player ID available yet, will register when OneSignal connects');
          // El registro se hará automáticamente cuando _handleSubscriptionChanged se ejecute
        }
      } catch (e, stackTrace) {
        Log.e(_tag, 'Error getting current device state', e, stackTrace);
      }
    }
    
    Log.i(_tag, 'Authenticated user configured successfully');
  } catch (e, stackTrace) {
    Log.e(_tag, 'Error setting authenticated user', e, stackTrace);
  }
}


/// ✅ NUEVO: Método para verificar el estado después de un delay
static Future<void> checkRegistrationAfterDelay() async {
  // Esperar 3 segundos y verificar si ya se registró
  await Future.delayed(const Duration(seconds: 3));
  
  if (_currentUserId != null && (_playerId == null || _playerId!.isEmpty)) {
    Log.d(_tag, 'Checking registration after delay...');
    
    try {
      final deviceState = await OneSignal.shared.getDeviceState();
      if (deviceState != null && deviceState.userId != null) {
        _playerId = deviceState.userId;
        _pushToken = deviceState.pushToken;
        
        Log.i(_tag, 'Player ID obtained after delay: $_playerId');
        await _registerDeviceInBackend(_playerId!);
      } else {
        Log.e(_tag, 'Still no player ID after delay');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error checking registration after delay', e, stackTrace);
    }
  }
}


  /// ✅ NUEVO: Método público para forzar el registro del dispositivo
  static Future<void> forceRegisterDevice() async {
    Log.i(_tag, 'Force registering device...');
    
    if (_currentUserId == null) {
      Log.e(_tag, 'Cannot register device: no authenticated user');
      return;
    }

    try {
      // Obtener estado actual del dispositivo
      final deviceState = await OneSignal.shared.getDeviceState();
      if (deviceState != null) {
        _playerId = deviceState.userId;
        _pushToken = deviceState.pushToken;
        
        if (_playerId != null && _playerId!.isNotEmpty) {
          await _registerDeviceInBackend(_playerId!);
        } else {
          Log.e(_tag, 'No player ID available for registration');
        }
      } else {
        Log.e(_tag, 'Device state not available');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error in force register device', e, stackTrace);
    }
  }

  /// Limpiar usuario autenticado
  static Future<void> clearAuthenticatedUser() async {
    Log.i(_tag, 'Clearing authenticated user');
    
    _currentUserId = null;
    
    try {
      await _storage.delete(key: 'auth_token');
      Log.i(_tag, 'User data cleared successfully');
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error clearing user data', e, stackTrace);
    }
  }

  /// Enviar notificación de prueba
  static Future<bool> sendTestNotification() async {
    Log.i(_tag, 'Sending test notification');
    
    try {
      final token = await _getTokenWithValidation();
      final url = Uri.parse('${Constants.baseUrl}/onesignal/test-notification');
      
      final headers = {
      'Authorization': 'Bearer $token', // CAMBIO: Bearer en lugar de Token
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Log.i(_tag, 'Test notification sent successfully');
        return true;
      } else {
        Log.e(_tag, 'Test notification failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error sending test notification', e, stackTrace);
      return false;
    }
  }

  /// Habilitar/deshabilitar notificaciones
  static Future<void> setNotificationsEnabled(bool enabled) async {
    Log.i(_tag, 'Setting notifications enabled: $enabled');
    
    try {
      await OneSignal.shared.disablePush(!enabled);
      
      final token = await _getTokenWithValidation();
      final endpoint = enabled ? 'enable-notifications' : 'disable-notifications';
      final url = Uri.parse('${Constants.baseUrl}/onesignal/$endpoint');
      
      final headers = {
      'Authorization': 'Bearer $token', // CAMBIO: Bearer en lugar de Token
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = enabled && _playerId != null 
          ? jsonEncode({'player_id': _playerId})
          : null;

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        Log.i(_tag, 'Notification settings updated successfully');
      } else {
        Log.e(_tag, 'Failed to update notification settings: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e(_tag, 'Error setting notifications enabled', e, stackTrace);
    }
  }

  /// Obtener token con validación siguiendo tu patrón
  static Future<String> _getTokenWithValidation() async {
    Log.d(_tag, 'Fetching token from TokenStorage');
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      Log.e(_tag, 'Invalid or missing token');
      throw Exception('Authentication required: Invalid token');
    }
    Log.d(_tag, 'Token retrieved successfully');
    return token;
  }

  /// Getters
  static bool get isInitialized => _isInitialized;
  static String? get playerId => _playerId;
  static String? get currentUserId => _currentUserId;
  static String? get pushToken => _pushToken; // ✅ NUEVO
  static String? get deviceType => _deviceType; // ✅ NUEVO

  /// Cleanup
  static Future<void> dispose() async {
    Log.i(_tag, 'Disposing OneSignalService');
    _isInitialized = false;
    _playerId = null;
    _currentUserId = null;
    _pushToken = null; // ✅ NUEVO
    _deviceType = null; // ✅ NUEVO
  }
}