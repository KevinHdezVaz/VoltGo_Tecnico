import 'dart:async';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/services/ChatNotificationProvider.dart';
import 'package:Voltgo_app/data/services/EarningsService.dart';
import 'package:Voltgo_app/data/services/NotificationBadge.dart';
import 'package:Voltgo_app/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_app/data/services/ServiceRequestService.dart';
import 'package:Voltgo_app/data/services/SoundService.dart';
import 'package:Voltgo_app/data/services/TechnicianService.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/MenuPage/findATechnician/IncomingRequestScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/findATechnician/RealTimeTrackingScreen.dart';
import 'package:Voltgo_app/ui/MenuPage/findATechnician/ServiceWorkScreen.dart';
import 'package:Voltgo_app/utils/OneSignalService.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/VehicleRegistrationDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:Voltgo_app/data/logic/dashboard/DashboardLogic.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Enum para controlar el estado y la UI del conductor
enum DriverStatus { offline, online, incomingRequest, enRouteToUser, onService }

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  late final DashboardLogic _logic;
  bool _isLoading = true;
  ServiceRequestModel? _activeRequest;
  bool _hasActiveService = false;

  DriverStatus _driverStatus = DriverStatus.offline;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _requestCheckTimer;

 // ✅ NUEVAS variables para OneSignal
  StreamSubscription? _newRequestSubscription;
  StreamSubscription? _serviceCancelledSubscription;
  StreamSubscription? _statusUpdateSubscription;

  Timer?
      _statusCheckTimer; // NUEVO: Timer para verificar el estado de la solicitud actual
  bool _isDialogShowing = false;
  ServiceRequestModel? _currentRequest;
  Timer? _locationUpdateTimer;
  Map<String, dynamic>? _earningsSummary;

  List<int> _unavailableRequestIds = [];
  String? _lastActiveServiceStatus;
  ServiceRequestModel? _activeServiceRequest;

  @override
  void initState() {
    super.initState();
    _logic = DashboardLogic();



 WidgetsBinding.instance.addPostFrameCallback((_) {
    OneSignalService.setContext(context);
  });
  
    _setupOneSignalListeners();

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_hasActiveService) {
        final expirationData = await TechnicianService.checkServiceExpiration();
        if (expirationData != null &&
            expirationData['time_info']?['expired'] == true) {
          // ✅ CANCELAR INMEDIATAMENTE EN EL BACKEND
          await TechnicianService.forceReleaseExpiredService();

          if (mounted) {
            // Verificar antes de setState
            setState(() {
              _hasActiveService = false;
              _activeRequest = null;
            });
          }
          setState(() {
            _hasActiveService = false;
            _activeRequest = null;
          });
          _showServiceExpiredDialog();
          timer.cancel();
        }
      }
    });

    _initializeApp();
  }

  @override
  void dispose() {
    _logic.dispose();
 
 
   NotificationService.stop().then((_) {
    NotificationService.dispose();
  });
  

     _newRequestSubscription?.cancel();
    _serviceCancelledSubscription?.cancel();
    _statusUpdateSubscription?.cancel();
    
    // ✅ NUEVO: Informar al backend que la app está cerrándose
    OneSignalService.updateAppState('background').catchError((e) {
      print('Error actualizando estado al cerrar: $e');
    });
    

    _stopLocationTracking();
    _stopRequestChecker();
    _unavailableRequestIds.clear();
    _stopActiveServiceMonitoring();
    _stopStatusChecker();

    // Cancelar cualquier timer adicional que puedas tener
    _requestCheckTimer?.cancel();
    _statusCheckTimer?.cancel();
    _locationUpdateTimer?.cancel();

    super.dispose();
  }

  void _showServiceExpiredDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations.serviceExpired),
        content: Text(localizations.serviceAutoCancelledAfterHour),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.understood),
          ),
        ],
      ),
    );
  }

Future<void> _initializeApp() async {
  setState(() => _isLoading = true);

  // Reinicializar NotificationService
  NotificationService.reinitialize();

  try {
    final profile = await TechnicianService.getProfile();
    final user = profile['user'];
    final bool hasVehicle = user['has_registered_vehicle'] == 1;

    try {
      final userId = user['id']?.toString();
      final token = await TokenStorage.getToken();
      
      if (userId != null && token != null) {
        await OneSignalService.setAuthenticatedUser(userId, token);
        print('OneSignal configurado en _initializeApp - Usuario: $userId');
        
        // ✅ NUEVO: Verificar después de un delay si no se registró inmediatamente
        OneSignalService.checkRegistrationAfterDelay();
      }
    } catch (e) {
      print('Error configurando OneSignal en _initializeApp: $e');
    }
    

    // Si no tiene vehículo, lo manda a registrarlo (lógica existente)
    if (!hasVehicle && mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => VehicleRegistrationScreen(
          onVehicleRegistered: () => _initializeApp(),
        ),
      ));
      setState(() => _isLoading = false);
      return;
    }

    // 1. Leer el estado guardado desde el perfil del técnico
    final serverStatus = profile['status'] ?? 'offline';
    final bool isOnline = serverStatus == 'available';

    // ✅ VERIFICAR SERVICIO ACTIVO ANTES DE ESTABLECER EL ESTADO
    bool hasActiveService = false;
    if (isOnline) {
      await _checkForActiveService();
      hasActiveService = _activeServiceRequest != null;
    }

    // 2. Establecer el estado inicial solo si NO hay servicio activo
    if (!hasActiveService) {
      setState(() {
        _driverStatus = isOnline ? DriverStatus.online : DriverStatus.offline;
      });
    }

    // 3. Iniciar servicios según el estado
    if (isOnline) {
      _startLocationTracking();
      if (!hasActiveService) {
        _startRequestChecker();
      }
    }

    // Cargar el mapa (lógica existente)
    final position = await _logic.getCurrentUserPosition();
    if (position != null && mounted) {
      final latLng = LatLng(position.latitude!, position.longitude!);
      setState(() {
        _logic.initialCameraPosition =
            CameraPosition(target: latLng, zoom: 16.0);
        _logic.updateUserMarker(latLng);
      });
      _centerMapOnUser(latLng);
    }

    // ✅ CARGAR GANANCIAS AL INICIALIZAR
    await _loadEarnings();
  } catch (e) {
    final localizations = AppLocalizations.of(context);
    _showErrorSnackbar('${localizations.errorLoadingData}: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}    

  Future<void> _checkForActiveService() async {
    try {
      print("🔍 Verificando si hay servicio activo al iniciar...");

      final response = await TechnicianService.getActiveService();

      if (response != null && response['has_active_service'] == true) {
        final serviceData = response['active_service'];

        print(
            "🎯 Servicio activo encontrado: ${serviceData['id']} - ${serviceData['status']}");

        final activeService = ServiceRequestModel.fromJson(serviceData);

        setState(() {
          _activeServiceRequest = activeService;
          _currentRequest = activeService;
          _lastActiveServiceStatus = activeService.status;
        });

        // ✅ REDIRIGIR SEGÚN EL ESTADO DEL SERVICIO
        if (activeService.status == 'on_site' ||
            activeService.status == 'charging') {
          // Si está en el sitio o cargando, ir directo a ServiceWorkScreen
          print(
              "🏠 Servicio en sitio/cargando - navegando a ServiceWorkScreen");

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ServiceWorkScreen(
                serviceRequest: activeService,
                onServiceComplete: () {
                  // ✅ VERIFICAR mounted ANTES DE setState
                  if (mounted) {
                    setState(() {
                      _driverStatus = DriverStatus.online;
                      _activeServiceRequest = null;
                      _currentRequest = null;
                      _lastActiveServiceStatus = null;
                    });
                    _loadEarnings(); // Recargar ganancias
                  }
                },
              ),
            ),
          );

          return; // Salir temprano para evitar establecer estados de UI
        } else {
          // Para otros estados (accepted, en_route), mostrar dashboard normal
          setState(() {
            switch (activeService.status) {
              case 'accepted':
              case 'en_route':
                _driverStatus = DriverStatus.enRouteToUser;
                break;
              default:
                _driverStatus = DriverStatus.online;
            }
          });
        }

        _startActiveServiceMonitoring();
        print("✅ Servicio activo restaurado: ${activeService.status}");
        return;
      } else {
        print("ℹ️ No hay servicio activo al iniciar");
      }
    } catch (e) {
      print("❌ Error verificando servicio activo: $e");
    }
  }

  Future<void> _centerMapOnUser(LatLng position) async {
    final GoogleMapController controller = await _logic.mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: 16.0, tilt: 30),
    ));
  }

  void _toggleOnlineStatus(bool isOnline) async {
    final newStatus = isOnline ? 'available' : 'offline';

    try {
      await TechnicianService.updateStatus(newStatus);

      await OneSignalService.updateAppState(isOnline ? 'foreground' : 'background');

      setState(() {
        _driverStatus = isOnline ? DriverStatus.online : DriverStatus.offline;

        if (isOnline) {
          _unavailableRequestIds.clear();
          _startLocationTracking();
          _startRequestChecker();
        } else {
          _stopLocationTracking();
          _stopRequestChecker();
          _stopStatusChecker();
          _stopActiveServiceMonitoring(); // ✅ NUEVO

          // Limpiar servicios activos
          _currentRequest = null;
          _activeServiceRequest = null;
          _lastActiveServiceStatus = null;
          _unavailableRequestIds.clear();
        }
      });
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _showErrorSnackbar(
          '${localizations.errorChangingStatus}: ${e.toString()}');
      setState(() {
        _driverStatus = !isOnline ? DriverStatus.online : DriverStatus.offline;
      });
    }
  }

  // Reemplaza tu método _startRequestChecker con este:

  void _startRequestChecker() {
    _stopRequestChecker();
    _requestCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isDialogShowing || _driverStatus != DriverStatus.online) return;

      print("🔄 Buscando nuevas solicitudes...");

      try {
        final List<Map<String, dynamic>> rawRequests =
            await TechnicianService.checkForNewRequests();

        // ✅ FILTRAR solicitudes que ya sabemos que no están disponibles
        final availableRequests = rawRequests
            .where((request) => !_unavailableRequestIds.contains(request['id']))
            .toList();

        if (availableRequests.isNotEmpty && mounted) {
          final rawRequest = availableRequests.first;

      
        try {
          await NotificationService.playIncomingRequestNotification();
          print('🎵📳 Notificación de solicitud entrante iniciada');
        } catch (e) {
          print('⚠️ No se pudo reproducir la notificación: $e');
        }

          print(
              "🎯 Nueva solicitud encontrada: ID ${rawRequest['id']}, Cliente: ${rawRequest['user_name']}, Distancia: ${rawRequest['distance']}");

          // ✅ VERIFICAR que la solicitud sigue siendo válida
          final status =
              await TechnicianService.getRequestStatus(rawRequest['id']);

          if (status == null) {
            print(
                "⚠️ Solicitud ${rawRequest['id']} ya no está disponible, agregando a lista de no disponibles");
            _unavailableRequestIds.add(rawRequest['id']);
            return;
          }

          if (status.status != 'pending') {
            print(
                "⚠️ Solicitud ${rawRequest['id']} no está pendiente (${status.status}), ignorando...");
            _unavailableRequestIds.add(rawRequest['id']);
            return;
          }

          // Verificar que no estemos ya mostrando esta solicitud
          if (_currentRequest != null &&
              _currentRequest!.id == rawRequest['id']) {
            print("⚠️ Ya se está mostrando esta solicitud, ignorando...");
            return;
          }

          // ✅ CREAR ServiceRequestModel desde los datos crudos
          final newRequest =
              _createServiceRequestFromRawData(rawRequest, status);

          _isDialogShowing = true;
          timer.cancel();

          setState(() {
            _currentRequest = newRequest;
            _driverStatus = DriverStatus.incomingRequest;
          });

          _startStatusChecker();

         try {
  final bool? accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => IncomingRequestDialog(serviceRequest: newRequest),
  );

  // ✅ SIEMPRE detener el sonido cuando el diálogo se cierre
  try {
    await NotificationService.stop();
    print('🔇 Sonido detenido después de cerrar diálogo');
  } catch (e) {
    print('⚠️ Error deteniendo sonido después de diálogo: $e');
  }

  _stopStatusChecker();

  // Procesar la respuesta
  if (accepted == true) {
    _acceptRequest(newRequest.id);
  } else {
    // Tanto false como null se tratan como rechazo
    _rejectRequest(newRequest.id);
  }

} catch (e) {
  // En caso de error, también detener el sonido
  print("❌ Error en showDialog: $e");
  try {
    await NotificationService.stop();
  } catch (stopError) {
    print('⚠️ Error deteniendo sonido después de error: $stopError');
  }
}

          _isDialogShowing = false;
          _startRequestChecker();
        }
      } catch (e) {
        print("❌ Error en _startRequestChecker: $e");
        // ✅ Si es error de autorización, limpiar lista de no disponibles después de un tiempo
        if (e.toString().contains('No autorizado')) {
          _cleanupUnavailableRequests();
        }
      }
    });
  }

// ✅ SOLUCIÓN 3: Usar DraggableScrollableSheet (más avanzado)
  void _showNavigationOptions() {
    if (_currentRequest == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5, // ✅ Inicia al 50% de la pantalla
        minChildSize: 0.3, // ✅ Mínimo 30%
        maxChildSize: 0.8, // ✅ Máximo 80%
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: _buildScrollableNavigationContent(scrollController),
        ),
      ),
    );
  }

// ✅ Contenido scrollable para el DraggableScrollableSheet
  Widget _buildScrollableNavigationContent(ScrollController scrollController) {
    final localizations = AppLocalizations.of(context);

    final clientName = _currentRequest?.user?.name ?? 'Cliente';
    final lat = _currentRequest!.requestLat;
    final lng = _currentRequest!.requestLng;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Handle visual
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Resto del contenido igual que antes pero en ListView
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.navigation, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.navigateToClient} $clientName',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Opciones de navegación
        ...[
          // Usar spread operator para agregar múltiples widgets
          _buildCompactNavigationOption(
            icon: Icons.map,
            title: 'Google Maps',
            subtitle: 'Navegación con tráfico',
            color: Colors.blue,
            onTap: () async {
              Navigator.pop(context);
              await _launchGoogleMaps(lat, lng, clientName);
            },
          ),
          const SizedBox(height: 12),
          _buildCompactNavigationOption(
            icon: Icons.directions_car,
            title: 'Waze',
            subtitle: 'Rutas optimizadas',
            color: Colors.purple,
            onTap: () async {
              Navigator.pop(context);
              await _launchWaze(lat, lng);
            },
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 20),

        // Botón cancelar
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Espacio final
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }


 void _setupOneSignalListeners() {
    print('Configurando listeners de OneSignal...');

    // Escuchar nuevas solicitudes de servicio
    _newRequestSubscription = OneSignalService.eventBus.on<NewServiceRequestEvent>().listen((event) {
      print('Evento OneSignal - Nueva solicitud: ${event.clientName}');
      _handleOneSignalNewRequest(event);
    });

    // Escuchar cancelaciones de servicio
    _serviceCancelledSubscription = OneSignalService.eventBus.on<ServiceCancelledEvent>().listen((event) {
      print('Evento OneSignal - Servicio cancelado: ${event.reason}');
      _handleOneSignalServiceCancelled(event);
    });

    // Escuchar actualizaciones de estado
    _statusUpdateSubscription = OneSignalService.eventBus.on<ServiceStatusUpdateEvent>().listen((event) {
      print('Evento OneSignal - Estado actualizado: ${event.newStatus}');
      _handleOneSignalStatusUpdate(event);
    });

    print('Listeners OneSignal configurados');
  }

  /// ✅ NUEVO: Manejar nueva solicitud desde OneSignal
  void _handleOneSignalNewRequest(NewServiceRequestEvent event) {
    print('Manejando nueva solicitud OneSignal: ${event.serviceRequestId}');

    // Solo procesar si estamos en estado online y no hay diálogo abierto
    if (_driverStatus == DriverStatus.online && !_isDialogShowing) {
      print('Estado válido para procesar solicitud OneSignal');
      
      // Realizar una búsqueda inmediata sin sonido (ya sonó la push)
      _checkForImmediateRequestsFromPush();
    } else {
      print('Estado no válido para solicitud OneSignal - Estado: $_driverStatus, Diálogo: $_isDialogShowing');
    }
  }



  /// ✅ NUEVO: Búsqueda inmediata sin sonido (activada por push notification)
  Future<void> _checkForImmediateRequestsFromPush() async {
    if (_isDialogShowing || _driverStatus != DriverStatus.online) {
      print('No se puede buscar - diálogo abierto o estado incorrecto');
      return;
    }
    
    print('Búsqueda inmediata activada por push notification...');
    
    try {
      final List<Map<String, dynamic>> rawRequests =
          await TechnicianService.checkForNewRequests();

      final availableRequests = rawRequests
          .where((request) => !_unavailableRequestIds.contains(request['id']))
          .toList();

      if (availableRequests.isNotEmpty && mounted) {
        print('Solicitudes encontradas por push: ${availableRequests.length}');
        
        // Detener búsqueda periódica para evitar conflictos
        _stopRequestChecker();
        
        final rawRequest = availableRequests.first;
        
        // ✅ NO reproducir sonido - la push notification ya sonó
        print('Procesando solicitud por push: ID ${rawRequest['id']}');

        final status = await TechnicianService.getRequestStatus(rawRequest['id']);

        if (status == null || status.status != 'pending') {
          print('Solicitud push no válida o ya no pendiente');
          _unavailableRequestIds.add(rawRequest['id']);
          _startRequestChecker(); // Reiniciar búsqueda normal
          return;
        }

        final newRequest = _createServiceRequestFromRawData(rawRequest, status);

        _isDialogShowing = true;

        setState(() {
          _currentRequest = newRequest;
          _driverStatus = DriverStatus.incomingRequest;
        });

        _startStatusChecker();

        final bool? accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => IncomingRequestDialog(serviceRequest: newRequest),
        );

        // ✅ IMPORTANTE: No llamar NotificationService.stop() aquí 
        // porque no se reprodujo sonido local

        _stopStatusChecker();

        if (accepted == true) {
          _acceptRequest(newRequest.id);
        } else {
          _rejectRequest(newRequest.id);
        }

        _isDialogShowing = false;
        _startRequestChecker(); // Reiniciar búsqueda normal
        
      } else {
        print('No hay solicitudes disponibles para push notification');
      }
    } catch (e) {
      print('Error en búsqueda inmediata por push: $e');
      _startRequestChecker(); // Asegurar que continúe la búsqueda normal
    }
  }


  /// ✅ NUEVO: Manejar cancelación desde OneSignal
  void _handleOneSignalServiceCancelled(ServiceCancelledEvent event) {
    print('Manejando cancelación OneSignal: ${event.serviceRequestId}');

    // Verificar si es nuestra solicitud activa
    if (_currentRequest != null && _currentRequest!.id == event.serviceRequestId) {
      print('Cancelación coincide con solicitud activa');
      _handleClientCancellation();
    } else if (_activeServiceRequest != null && _activeServiceRequest!.id == event.serviceRequestId) {
      print('Cancelación coincide con servicio activo');
      _handleClientCancellation();
    } else {
      print('Cancelación no coincide con solicitudes actuales');
    }
  }

  /// ✅ NUEVO: Manejar actualización de estado desde OneSignal
  void _handleOneSignalStatusUpdate(ServiceStatusUpdateEvent event) {
    print('Manejando actualización OneSignal: ${event.serviceRequestId} -> ${event.newStatus}');

    // Refrescar datos si coincide con nuestro servicio
    if (_currentRequest != null && _currentRequest!.id == event.serviceRequestId) {
      _refreshServiceData();
    }
  }


  Widget _buildNavigationSheet() {
    final localizations = AppLocalizations.of(context);

    final clientName = _currentRequest?.user?.name ?? 'Cliente';
    final lat = _currentRequest!.requestLat;
    final lng = _currentRequest!.requestLng;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Título y ubicación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.navigation,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Navegar hacia',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            clientName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Información de ubicación
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Opciones de navegación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Google Maps
                _buildNavigationOption(
                  icon: Icons.map,
                  title: localizations.googleMaps,
                  subtitle: localizations.navigationWithTraffic,
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchGoogleMaps(lat, lng, clientName);
                  },
                ),

                const SizedBox(height: 12),

                // Waze
                _buildNavigationOption(
                  icon: Icons.directions_car,
                  title: localizations.waze,
                  subtitle: localizations.optimizedRoutes,
                  color: Colors.purple,
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchWaze(lat, lng);
                  },
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botón cancelar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Espacio extra para el safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

// ✅ NUEVO: Widget de opción de navegación más compacto
  Widget _buildCompactNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10), // ✅ REDUCIDO
      child: Container(
        padding: const EdgeInsets.all(12), // ✅ REDUCIDO de 16 a 12
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(10), // ✅ REDUCIDO
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // ✅ REDUCIDO de 12 a 8
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8), // ✅ REDUCIDO
              ),
              child:
                  Icon(icon, color: color, size: 20), // ✅ REDUCIDO de 24 a 20
            ),
            const SizedBox(width: 12), // ✅ REDUCIDO de 16 a 12
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14, // ✅ REDUCIDO de 16 a 14
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2), // ✅ REDUCIDO de 4 a 2
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11, // ✅ REDUCIDO de 12 a 11
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18, // ✅ REDUCIDO de 20 a 18
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _launchGoogleMaps(double lat, double lng, String destination) async {
  try {
    // URL para abrir Google Maps con navegación
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    
    // URL alternativa más específica
    // final String googleMapsUrl = 'google.navigation:q=$lat,$lng&mode=d';
    
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      print('✅ Google Maps abierto exitosamente');
    } else {
      _showErrorSnackbar('Google Maps no está disponible');
    }
  } catch (e) {
    print('❌ Error abriendo Google Maps: $e');
    _showErrorSnackbar('No se pudo abrir Google Maps: $e');
  }
}

  Future<void> _launchWaze(double lat, double lng) async {
    try {
      final wazeUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
      final uri = Uri.parse(wazeUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Waze abierto exitosamente');
      } else {
        _showErrorSnackbar('Waze no está instalado en tu dispositivo');
      }
    } catch (e) {
      print('❌ Error abriendo Waze: $e');
      _showErrorSnackbar('No se pudo abrir Waze');
    }
  }

  Future<void> _launchBestNavigationApp(
      double lat, double lng, String destination) async {
    try {
      // Intentar Google Maps primero
      try {
        //      await MapsLauncher.launchCoordinates(lat, lng, destination);
        print('✅ Google Maps abierto exitosamente (auto)');
        return;
      } catch (e) {
        print('⚠️ Google Maps no disponible, intentando Waze...');
      }

      // Si Google Maps falla, intentar Waze
      final wazeUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
      final uri = Uri.parse(wazeUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Waze abierto exitosamente (auto)');
        return;
      }

      // Si todo falla
      _showErrorSnackbar('No hay apps de navegación disponibles');
    } catch (e) {
      print('❌ Error en navegación automática: $e');
      _showErrorSnackbar('No se pudo abrir ninguna app de navegación');
    }
  }

// ✅ NUEVO: Método para crear ServiceRequestModel desde datos crudos
  ServiceRequestModel _createServiceRequestFromRawData(
      Map<String, dynamic> rawRequest, ServiceRequestModel statusData) {
    return ServiceRequestModel(
      id: rawRequest['id'],
      userId: rawRequest['user_id'],
      technicianId: statusData.technicianId,
      status: statusData.status,
      requestLat: double.parse(rawRequest['request_lat'].toString()),
      requestLng: double.parse(rawRequest['request_lng'].toString()),
      estimatedCost: statusData.estimatedCost,
      finalCost: statusData.finalCost,
      requestedAt: statusData.requestedAt,
      acceptedAt: statusData.acceptedAt,
      completedAt: statusData.completedAt,
      user: statusData.user ??
          UserModel(
            id: rawRequest['user_id'],
            name: rawRequest['user_name'] ?? 'Cliente',
            email: '',
            userType: 'user',
          ),
      technician: statusData.technician,
      // ✅ PROPIEDADES específicas para UI del técnico
      clientName: rawRequest['user_name'] ?? 'Cliente',
      formattedDistance: rawRequest['distance'] ?? '0 km',
      formattedEarnings:
          '\$${double.parse(rawRequest['base_cost']?.toString() ?? '5.00').toStringAsFixed(2)}',
    );
  }

  void _cleanupUnavailableRequests() {
    Timer(const Duration(minutes: 2), () {
      if (mounted) {
        setState(() {
          _unavailableRequestIds.clear();
        });
        print("🧹 Lista de solicitudes no disponibles limpiada");
      }
    });
  }

// También actualiza tu método _buildIncomingRequestPanel:
  

  void _stopRequestChecker() {
    _requestCheckTimer?.cancel();
    _requestCheckTimer = null;
  }

  void _startStatusChecker() {
    _stopStatusChecker();
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_currentRequest == null ||
          _driverStatus != DriverStatus.incomingRequest ||
          !_isDialogShowing) {
        timer.cancel();
        return;
      }

      try {
        final status =
            await TechnicianService.getRequestStatus(_currentRequest!.id);

        if (status == null) {
          print(
              "⚠️ Solicitud ${_currentRequest!.id} ya no está disponible, cerrando diálogo...");
          _handleRequestUnavailable();
          timer.cancel();
          return;
        }

        print(
            "🔍 Status check for request ${_currentRequest!.id}: ${status.status}");

        if (status.status == 'cancelled' && mounted) {
          print("⚠️ Solicitud cancelada, cerrando diálogo...");
          _handleRequestCancelled();
          timer.cancel();
        } else if (status.status != 'pending' && mounted) {
          print(
              "⚠️ Solicitud ya no está pendiente (${status.status}), cerrando diálogo...");
          _handleRequestUnavailable();
          timer.cancel();
        }
      } catch (e) {
        print("❌ Error verificando estado: $e");
        // ✅ Si es error 403, la solicitud ya no está disponible
        if (e.toString().contains('No autorizado')) {
          print(
              "⚠️ Error 403: Solicitud ya no está disponible para este técnico");
          _handleRequestUnavailable();
          timer.cancel();
        }
      }
    });
  }

  // ✅ NUEVO: Manejar cuando una solicitud ya no está disponible
  void _handleRequestUnavailable() {
    final localizations = AppLocalizations.of(context);


  NotificationService.stop().catchError((e) {
    print('⚠️ Error al detener notificación: $e');
  });
    NotificationService.vibrateOnly(VibrationPattern.urgent);


    if (_currentRequest != null) {
      _unavailableRequestIds.add(_currentRequest!.id);
    }

    // Cerrar el diálogo si está abierto
    if (_isDialogShowing && Navigator.canPop(context)) {
      Navigator.of(context).pop(false);
    }

    // Actualizar el estado
    setState(() {
      _driverStatus = DriverStatus.online;
      _currentRequest = null;
      _isDialogShowing = false;
    });

    _showErrorSnackbar(localizations.requestNoLongerAvailable);
    _startRequestChecker(); // Reiniciar la búsqueda de solicitudes
  }

  // ✅ NUEVO: Manejar cuando una solicitud es cancelada
  void _handleRequestCancelled() {
    final localizations = AppLocalizations.of(context);

  // ✅ CORREGIDO: Detener notificación
  NotificationService.stop().catchError((e) {
    print('⚠️ Error al detener notificación: $e');
  });
  
  // Vibración para cancelación
  NotificationService.vibrateOnly(VibrationPattern.single);
    // Cerrar el diálogo si está abierto
    if (_isDialogShowing && Navigator.canPop(context)) {
      Navigator.of(context).pop(false);
    }

    // Actualizar el estado
    setState(() {
      _driverStatus = DriverStatus.online;
      _currentRequest = null;
      _isDialogShowing = false;
    });

    _showErrorSnackbar(localizations.clientCancelledRequest);
    _startRequestChecker(); // Reiniciar la búsqueda de solicitudes
  }

  // NUEVO: Método para detener la verificación de estado
  void _stopStatusChecker() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

void _acceptRequest(int requestId) async {
  final localizations = AppLocalizations.of(context);

  try {
    await NotificationService.stop();
    NotificationService.vibrateOnly(VibrationPattern.gentle);
    print('🔇 Notificación detenida y feedback de aceptación enviado');
  } catch (e) {
    print('⚠️ Error al detener notificación: $e');
  }

  // ✅ IMPORTANTE: NO limpiar _currentRequest aquí
  setState(() {
    _driverStatus = DriverStatus.enRouteToUser;
    _isDialogShowing = false;
    // ✅ NO hacer _currentRequest = null aquí
  });

  try {
    final success = await TechnicianService.acceptRequest(requestId);
    if (success) {
      _showSuccessSnackbar(localizations.requestAccepted);
      await NotificationService.playGentleNotification();

      // ✅ MANTENER _currentRequest para el panel
      _activeServiceRequest = _currentRequest;
      _lastActiveServiceStatus = 'accepted';
      _startActiveServiceMonitoring();

      _unavailableRequestIds.clear();
      
      // ✅ DEBUGGING: Verificar que _currentRequest no es null
      print("✅ Solicitud aceptada - _currentRequest: ${_currentRequest?.id}");
      print("✅ Estado actual: $_driverStatus");
    }
  } catch (e) {
    // Error handling...
    setState(() {
      _driverStatus = DriverStatus.online;
      _currentRequest = null; // ✅ Solo limpiar en caso de error
    });
    _startRequestChecker();
  }
}    

// ✅ NUEVO: Monitorear servicio activo para detectar cancelaciones
  void _startActiveServiceMonitoring() {
    _stopActiveServiceMonitoring(); // Detener cualquier monitoreo previo

    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeServiceRequest == null ||
          _driverStatus == DriverStatus.online ||
          _driverStatus == DriverStatus.offline) {
        timer.cancel();
        return;
      }

      try {
        final updatedRequest =
            await TechnicianService.getRequestStatus(_activeServiceRequest!.id);

        if (updatedRequest == null) {
          // Solicitud no encontrada - probablemente cancelada
          print("⚠️ Servicio activo no encontrado - cancelado por cliente");
          _handleClientCancellation();
          timer.cancel();
          return;
        }

        // Detectar cambio de estado a 'cancelled'
        if (updatedRequest.status == 'cancelled' &&
            _lastActiveServiceStatus != 'cancelled') {
          print("⚠️ Cliente canceló el servicio");
          _handleClientCancellation();
          timer.cancel();
          return;
        }

        // Actualizar estado conocido
        _lastActiveServiceStatus = updatedRequest.status;

        // Actualizar datos del servicio si hay cambios
        if (updatedRequest.status != _activeServiceRequest?.status) {
          setState(() {
            _activeServiceRequest = updatedRequest;
          });
        }
      } catch (e) {
        print("❌ Error monitoreando servicio activo: $e");

        // Si es error 403, probablemente el servicio fue cancelado
        if (e.toString().contains('No autorizado')) {
          print("⚠️ Error 403 en monitoreo - servicio cancelado");
          _handleClientCancellation();
          timer.cancel();
        }
      }
    });
  }

  // ✅ NUEVO: Detener monitoreo de servicio activo
  void _stopActiveServiceMonitoring() {
    // El timer se maneja automáticamente en _startActiveServiceMonitoring
  }

  // ✅ NUEVO: Manejar cancelación por parte del cliente
  void _handleClientCancellation() {
    if (!mounted) return;

    // Vibración fuerte para llamar la atención
  NotificationService.playUrgentNotification().catchError((e) {
    print('⚠️ Error reproduciendo notificación urgente: $e');
  });

    // Mostrar diálogo de cancelación
    _showClientCancellationDialog();

    // Actualizar estado
    setState(() {
      _driverStatus = DriverStatus.online;
      _activeServiceRequest = null;
      _currentRequest = null;
      _lastActiveServiceStatus = null;
    });

    // Reiniciar búsqueda de solicitudes
    _startRequestChecker();
  }

  void _showSuccessNotification(String message) {
  NotificationService.playGentleNotification().catchError((e) {
    print('⚠️ Error reproduciendo notificación suave: $e');
  });
  _showSuccessSnackbar(message);
}

// ✅ NUEVO: Método para notificaciones de error
void _showErrorNotification(String message) {
  NotificationService.vibrateOnly(VibrationPattern.urgent);
  _showErrorSnackbar(message);
}


  // ✅ NUEVO: Diálogo cuando cliente cancela
  void _showClientCancellationDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.cancel_outlined,
                color: Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.serviceCancelledTitle,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.clientCancelledService,
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        localizations.timeCompensation,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.partialCompensationMessage,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.willContinueReceivingRequests,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Entendido',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Notificación flotante rápida para cancelaciones
  void _showQuickCancellationNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cancel, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Servicio Cancelado',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'El cliente canceló el servicio',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ✅ CORREGIR _rejectRequest
  void _rejectRequest(int requestId) async {

     try {
    await NotificationService.stop();
    print('🔇 Notificación detenida al rechazar solicitud');
  } catch (e) {
    print('⚠️ Error al detener notificación: $e');
  }


    try {
      final success = await TechnicianService.rejectRequest(requestId);
      if (success) {
        print("✅ Solicitud $requestId rechazada exitosamente");
        // ✅ NO agregar a lista de no disponibles porque fue rechazada voluntariamente
      }
    } catch (e) {
      print("❌ Error al rechazar en el servidor: $e");
      // ✅ Si falla el rechazo, agregar a lista de no disponibles
      _unavailableRequestIds.add(requestId);
    } finally {
      setState(() {
        _driverStatus = DriverStatus.online;
        _currentRequest = null;
        _isDialogShowing = false;
      });
      _startRequestChecker();
    }
  }

  // ELIMINADO: _checkRequestStatusPeriodically() ya no es necesario
  Future<void> _startLocationTracking() async {
    final localizations = AppLocalizations.of(context);

    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await _location.requestService();
    if (!serviceEnabled) {
      _showErrorSnackbar(localizations.pleaseEnableLocation);
      _toggleOnlineStatus(false);
      return;
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        _showErrorSnackbar(localizations.locationPermissionRequired);
        _toggleOnlineStatus(false);
        return;
      }
    }

    // Cancela cualquier temporizador anterior para evitar duplicados
    _locationUpdateTimer?.cancel();

    // Inicia un nuevo temporizador que se ejecuta cada 30 segundos
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        // Obtiene la ubicación actual una vez
        final LocationData newLocation = await _location.getLocation();

        if (mounted &&
            newLocation.latitude != null &&
            newLocation.longitude != null) {
          print("📍 Enviando ubicación al backend (cada 30 seg)...");

          // Envía las coordenadas al servidor
          TechnicianService.updateLocation(
            newLocation.latitude!,
            newLocation.longitude!,
          );

          final newLatLng =
              LatLng(newLocation.latitude!, newLocation.longitude!);

          // Actualiza el marcador en el mapa sin mover la cámara bruscamente
          setState(() {
            _logic.updateUserMarker(newLatLng);
          });
        }
      } catch (e) {
        print("❌ Error al obtener la ubicación periódicamente: $e");
      }
    });
  }

  void _stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    print("Rastreo de ubicación detenido.");
  }

  void _updateServiceStatus() {
    setState(() {
      if (_driverStatus == DriverStatus.enRouteToUser) {
        _driverStatus = DriverStatus.onService;
      } else if (_driverStatus == DriverStatus.onService) {
        // ✅ LIMPIAR COMPLETAMENTE EL ESTADO AL COMPLETAR SERVICIO
        _driverStatus = DriverStatus.online;
        _activeServiceRequest = null;
        _currentRequest = null;
        _lastActiveServiceStatus = null;
        _hasActiveService =
            false; // ✅ IMPORTANTE: Limpiar esta variable también

        // ✅ DETENER monitoreo al completar servicio
        _stopActiveServiceMonitoring();

        // ✅ REINICIAR búsqueda de nuevas solicitudes
        _startRequestChecker();

        // Recargar ganancias después de completar un servicio
        _loadEarnings();

        // Mostrar mensaje de éxito
        _showSuccessSnackbar('¡Servicio completado exitosamente!');
      }
    });
  }

  Future<void> _loadEarnings() async {
    try {
      final summary = await EarningsService.getEarningsSummary();
      if (summary != null && mounted) {
        setState(() {
          _earningsSummary = summary;
        });
      }
    } catch (e) {
      print('❌ Error cargando ganancias: $e');
    }
  }

// ✅ SOLUCIÓN 2: Ajustar el build method para más espacio
  @override
  Widget build(BuildContext context) {
 print("🏗️ Building dashboard - Estado: $_driverStatus, Request: ${_currentRequest?.id}");
  print("🔍 Verificando condiciones:");
  print("   - _driverStatus == DriverStatus.enRouteToUser: ${_driverStatus == DriverStatus.enRouteToUser}");
  print("   - _driverStatus == DriverStatus.onService: ${_driverStatus == DriverStatus.onService}");
  print("   - _currentRequest != null: ${_currentRequest != null}");
  

    final headerHeight = MediaQuery.of(context).padding.top + 64;
    final topPanelHeight = 160;
    final bottomNavHeight = 100; // ✅ AUMENTADO de 80 a 100

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _logic.initialCameraPosition,
            onMapCreated: (GoogleMapController controller) async {
              _logic.mapController.complete(controller);
              String mapStyle =
                  await rootBundle.loadString('assets/map_style.json');
              controller.setMapStyle(mapStyle);
            },
            markers: _logic.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            padding: EdgeInsets.only(
              top: headerHeight + topPanelHeight + 16,
              bottom: _driverStatus == DriverStatus.offline ||
                      _driverStatus == DriverStatus.online
                  ? 76
                  : 220, // ✅ AUMENTADO de 150 a 220 para dar más espacio
            ),
          ),
          // Header fijo en la parte superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
          // Panel de estadísticas debajo del header
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 0,
            right: 0,
            child: _buildTopHeaderPanel(),
          ),
          // Paneles de estado
         if (_driverStatus == DriverStatus.enRouteToUser ||
            _driverStatus == DriverStatus.onService) ...[
          Builder(
            builder: (context) {
              print("🔧 Intentando mostrar panel activo");
              print("🔧 _currentRequest en builder: ${_currentRequest?.id}");
              return Positioned(
                bottom: bottomNavHeight + 32,
                left: 16,
                right: 16,
                child: _buildActiveServicePanel(),
              );
            },
          ),
        ] else ...[
          // ✅ DEBUGGING: Mostrar por qué no se muestra el panel
          Builder(
            builder: (context) {
              print("❌ Panel NO se muestra - Estado actual: $_driverStatus");
              return SizedBox.shrink();
            },
          ),
        ],
        
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      
        ],
      ),
    );
  }

  String _getStatusTitle() {
    final localizations = AppLocalizations.of(context);
    switch (_driverStatus) {
      case DriverStatus.offline:
        return localizations.voltgoTechnician;
      case DriverStatus.online:
        return localizations
            .searchingRequestsText; // Assuming you fixed this as per the previous response
      case DriverStatus.incomingRequest:
        return localizations.newRequest;
      case DriverStatus.enRouteToUser:
        return localizations
            .enRouteToClientPanel; // Use enRouteToClientPanel instead of enRouteToClient
      case DriverStatus.onService:
        return localizations.serviceInProgress;
    }
  }

  String _getStatusSubtitle() {
    final localizations = AppLocalizations.of(context);
    switch (_driverStatus) {
      case DriverStatus.online:
        return localizations.waitingForRequests;
      case DriverStatus.incomingRequest:
        return localizations.reviewingIncomingRequest;
      case DriverStatus.enRouteToUser:
        return localizations.headToClientLocation;
      case DriverStatus.onService:
        return localizations.chargingClientVehicle;
      default:
        return '';
    }
  }

// También asegúrate de que _buildHeader tenga una altura consistente
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary, // Color de fondo (puedes cambiarlo)
              borderRadius: BorderRadius.circular(
                  12), // Radio de las esquinas redondeadas
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(8), // Espaciado interno
            child: Image.asset(
              'assets/images/logoAppVoltgo.png',
              height: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusTitle(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_driverStatus != DriverStatus.offline)
                  Text(
                    _getStatusSubtitle(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // ELIMINADO: El switch se movió al _buildTopHeaderPanel
          const SizedBox(width: 48), // Espacio para mantener el balance visual
        ],
      ),
    );
  }

// En tu clase _DriverDashboardScreenState

  Widget _buildTopHeaderPanel() {
    final localizations = AppLocalizations.of(context);

    // Determinar el estado actual para la lógica de la UI
    final bool isOnline = _driverStatus != DriverStatus.offline;
    final bool isDuringService = _driverStatus == DriverStatus.enRouteToUser ||
        _driverStatus == DriverStatus.onService;

    // Obtener valores de ganancias de forma segura, con valores por defecto
    final todayEarnings = double.tryParse(
            _earningsSummary?['today']?['earnings']?.toString() ?? '0') ??
        0.0;
    final todayServices = int.tryParse(
            _earningsSummary?['today']?['services']?.toString() ?? '0') ??
        0;
    final todayRating = double.tryParse(
            _earningsSummary?['today']?['rating']?.toString() ?? '5.0') ??
        5.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [AppColors.brandBlue, AppColors.primary.withOpacity(0.9)]
              : [AppColors.textSecondary, AppColors.textDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? AppColors.brandBlue.withOpacity(0.25)
                : AppColors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Fila principal: Estado y Switch ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicador de estado (Punto y Texto)
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color:
                                isOnline ? AppColors.accent : AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: isOnline
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // El texto cambia si hay un servicio activo
                            Text(
                              isDuringService
                                  ? localizations.serviceActive
                                  : (isOnline
                                      ? localizations.online
                                      : localizations.offline),
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (isOnline && !isDuringService)
                              Text(
                                localizations.searchingRequests,
                                style: TextStyle(
                                  color:
                                      AppColors.textOnPrimary.withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Switch para cambiar de estado
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: isOnline,
                      // Si está en servicio, onChanged es null, lo que deshabilita el switch
                      onChanged: isDuringService ? null : _toggleOnlineStatus,
                      activeColor: AppColors.accent,
                      activeTrackColor: AppColors.accent.withOpacity(0.3),
                      inactiveThumbColor: AppColors.lightGrey,
                      inactiveTrackColor: AppColors.disabled.withOpacity(0.3),
                      // Color del pulgar cuando está deshabilitado
                      thumbColor: isDuringService
                          ? MaterialStateProperty.all(AppColors.disabled)
                          : null,
                    ),
                  ),
                ],
              ),

              // --- Estadísticas (solo se muestran si está en línea) ---
              if (isOnline) ...[
                const SizedBox(height: 12),
                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.textOnPrimary.withOpacity(0.15),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCompactStat(
                      icon: Icons.attach_money,
                      label: localizations.hoy,
                      value: '\$${todayEarnings.toStringAsFixed(2)}',
                      iconColor: AppColors.accent,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: AppColors.textOnPrimary.withOpacity(0.15),
                    ),
                    _buildCompactStat(
                      icon: Icons.electric_bolt,
                      label: localizations.services,
                      value: todayServices.toString(),
                      iconColor: AppColors.warning,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: AppColors.textOnPrimary.withOpacity(0.15),
                    ),
                    _buildCompactStat(
                      icon: Icons.star,
                      label: 'Rating',
                      value: todayRating.toStringAsFixed(1),
                      iconColor: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _refreshServiceData() async {
    try {
      // ✅ CORREGIDO: Usar _currentRequest en lugar de _activeRequest
      if (_currentRequest != null) {
        final updatedRequest =
            await ServiceRequestService.getRequestStatus(_currentRequest!.id);
        setState(() {
          _currentRequest = updatedRequest; // ✅ Actualizar _currentRequest
          // También actualizar _activeServiceRequest si es necesario
          _activeServiceRequest = updatedRequest;
        });
      }
    } catch (e) {
      print('Error refreshing service data: $e');
    }
  }

// ✅ MÉTODO _openChat ACTUALIZADO PARA MARCAR COMO LEÍDO
// En DriverDashboardScreen

void _openChat() async {
  if (_currentRequest == null) {
    _showErrorSnackbar('No hay servicio activo');
    return;
  }

  HapticFeedback.lightImpact();

  print('🔍 Abriendo chat para servicio: ${_currentRequest!.id}');
  print('📱 Usuario: ${_currentRequest!.user?.name ?? 'Desconocido'}');

  // ✅ MARCAR COMO LEÍDO ANTES DE ABRIR EL CHAT
  final chatProvider = Provider.of<ChatNotificationProvider>(context, listen: false);
  await chatProvider.markServiceAsRead(_currentRequest!.id);

  // Navegar a la pantalla de chat
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServiceChatScreen(
        serviceRequest: _currentRequest!,
        userType: 'technician',
      ),
    ),
  ).then((_) {
    // ✅ REFRESH AL VOLVER DEL CHAT
    chatProvider.forceRefresh();
  });
}


// Widget auxiliar para estadísticas compactas
  Widget _buildCompactStat({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: iconColor ?? AppColors.textOnPrimary.withOpacity(0.9),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textOnPrimary.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Widget auxiliar para las tarjetas de estadísticas
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    String? trend,
    bool? trendUp,
    bool isRating = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 16,
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendUp!
                        ? Colors.greenAccent.withOpacity(0.2)
                        : Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: trendUp ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isRating)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  subtitle ?? '',
                  style: TextStyle(
                    color: Colors.yellowAccent.withOpacity(0.9),
                    fontSize: 10,
                    letterSpacing: -1,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (subtitle != null && !isRating)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

 
Widget _buildActiveServicePanel() {
  final localizations = AppLocalizations.of(context);

  print("🔍 Building active service panel - _currentRequest: ${_currentRequest?.id}");

  if (_currentRequest == null) {
    print("⚠️ _currentRequest es null en _buildActiveServicePanel");
    return const SizedBox.shrink();
  }

  final bool enRuta = _driverStatus == DriverStatus.enRouteToUser;
  print("🚗 enRuta: $enRuta, _driverStatus: $_driverStatus");

  final String title = enRuta
      ? localizations.enRouteToClientPanel
      : localizations.serviceInProgressPanel;

  return Card(
    margin: EdgeInsets.zero,
    elevation: 10,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del Panel
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const Divider(height: 16),

          // Información del Cliente
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  _currentRequest!.user?.name.isNotEmpty == true
                      ? _currentRequest!.user!.name[0].toUpperCase()
                      : 'C',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nombre y Dirección
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentRequest!.user?.name ?? 'Cliente',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.chargeServiceRequested,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botones de acción
          if (enRuta) ...[
            // Botones para cuando está en ruta
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ✅ BOTÓN DE CHAT CON BADGE MEJORADO
                Consumer<ChatNotificationProvider>(
                  builder: (context, chatProvider, child) {
                    final unreadCount = _currentRequest != null 
                        ? chatProvider.getUnreadForService(_currentRequest!.id)
                        : 0;

                    return _buildChatButtonWithBadge(
                      unreadCount: unreadCount,
                      onTap: _openChat,
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Botón de Llamada
                OutlinedButton(
                  onPressed: _callClient,
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    side: BorderSide(color: AppColors.success),
                  ),
                  child: Icon(Icons.phone, color: AppColors.success, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botón para navegación
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.navigation, size: 16),
                label: Text(
                  'Abrir en Maps',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: _showNavigationOptions,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Botones para cuando está en servicio
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('NAVEGAR', style: TextStyle(fontSize: 12)),
                    onPressed: _showNavigationOptions,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.brandBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // ✅ BOTÓN DE CHAT CON BADGE MEJORADO
                Consumer<ChatNotificationProvider>(
                  builder: (context, chatProvider, child) {
                    final unreadCount = _currentRequest != null 
                        ? chatProvider.getUnreadForService(_currentRequest!.id)
                        : 0;

                    return _buildChatButtonWithBadge(
                      unreadCount: unreadCount,
                      onTap: _openChat,
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Botón de Llamada
                OutlinedButton(
                  onPressed: _callClient,
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    side: BorderSide(color: AppColors.success),
                  ),
                  child: Icon(Icons.phone, color: AppColors.success, size: 18),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Botón principal de seguimiento
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.my_location,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                "SEGUIMIENTO EN TIEMPO REAL",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _openRealTimeTracking,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: enRuta ? AppColors.primary : AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ✅ MÉTODO AUXILIAR PARA BOTÓN DE CHAT CON BADGE OPTIMIZADO
Widget _buildChatButtonWithBadge({
  required int unreadCount,
  required VoidCallback onTap,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // Botón principal
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(10),
          side: BorderSide(color: AppColors.info),
        ),
        child: Icon(
          Icons.chat,
          color: AppColors.info,
          size: 18, // ✅ Tamaño normal del icono
        ),
      ),
      
      // Badge pequeño y bien posicionado
      if (unreadCount > 0)
        Positioned(
          top: -2, // ✅ Posición más precisa
          right: -2,
          child: Container(
             padding: EdgeInsets.all(unreadCount > 9 ? 3 : 4), // ✅ Padding ajustable
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8), // ✅ Menos redondeado
              border: Border.all(
                color: Colors.white,
                width: 1.5, // ✅ Borde más fino
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2, // ✅ Sombra más sutil
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 9, // ✅ Texto más pequeño
                fontWeight: FontWeight.bold,
                height: 1, // ✅ Sin espacio extra vertical
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
}
// ✅ PASO 3: Agregar método para abrir seguimiento en tiempo real

  void _openRealTimeTracking() {
    if (_currentRequest == null) {
      _showErrorSnackbar('No hay servicio activo');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealTimeTrackingScreen(
          serviceRequest: _currentRequest!,
          onServiceComplete: () {
            // Callback cuando el servicio se marca como completado
            setState(() {
              _driverStatus = DriverStatus.onService;
            });
          },
        ),
      ),
    );
  }

  void _callClient() async {
    final localizations = AppLocalizations.of(context);

    // Ensure there is an active request
    if (_currentRequest == null || _currentRequest!.user == null) {
      _showErrorSnackbar(localizations.noClientInformationAvailable);
      return;
    }

    // Get the client's phone number
    final clientPhone = _currentRequest!.user!.phone?.toString();

    // Check if the phone number is valid
    if (clientPhone == null || clientPhone.isEmpty) {
      _showErrorSnackbar(localizations.noPhoneNumberAvailable);
      return;
    }

    // Prepare the URI for the phone call using the 'tel:' scheme
    final Uri phoneUri = Uri(scheme: 'tel', path: clientPhone);

    try {
      // Check if the phone call can be launched
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        print('✅ Llamada iniciada al cliente: $clientPhone');
      } else {
        _showErrorSnackbar(localizations.couldNotOpenPhoneApp);
      }
    } catch (e) {
      print('❌ Error al intentar llamar: $e');
      _showErrorSnackbar('Error al intentar llamar: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
