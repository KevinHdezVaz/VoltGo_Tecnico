import 'dart:async';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/services/EarningsService.dart';
import 'package:Voltgo_app/data/services/TechnicianService.dart';
import 'package:Voltgo_app/ui/MenuPage/findATechnician/IncomingRequestScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:Voltgo_app/data/logic/dashboard/DashboardLogic.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';

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
  DriverStatus _driverStatus = DriverStatus.offline;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _requestCheckTimer;
  Timer?
      _statusCheckTimer; // NUEVO: Timer para verificar el estado de la solicitud actual
  bool _isDialogShowing = false;
  ServiceRequestModel? _currentRequest;
  Map<String, dynamic>? _earningsSummary;

  @override
  void initState() {
    super.initState();
    _logic = DashboardLogic();
    _initializeApp();
  }

  @override
  void dispose() {
    _logic.dispose();
    _stopLocationTracking();
    _stopRequestChecker();
    _stopStatusChecker(); // NUEVO: Detener el timer de verificación de estado
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    try {
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
    } catch (e) {
      _showErrorSnackbar('Error al cargar el mapa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      setState(() {
        _driverStatus = isOnline ? DriverStatus.online : DriverStatus.offline;
        if (isOnline) {
          _startLocationTracking();
          _startRequestChecker();
        } else {
          _stopLocationTracking();
          _stopRequestChecker();
          _stopStatusChecker(); // NUEVO: Detener verificación de estado al desconectarse
          _currentRequest = null; // Limpiar solicitud actual
        }
      });
    } catch (e) {
      _showErrorSnackbar('Error al cambiar de estado: ${e.toString()}');
      setState(() {
        _driverStatus = !isOnline ? DriverStatus.online : DriverStatus.offline;
      });
    }
  }

  void _startRequestChecker() {
    _stopRequestChecker();
    _requestCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isDialogShowing || _driverStatus != DriverStatus.online) return;
      print("🔄 Buscando nuevas solicitudes...");
      final newRequest = await TechnicianService.checkForNewRequest();
      if (newRequest != null && mounted) {
        // Verify the request is still valid before showing
        try {
          final status =
              await TechnicianService.getRequestStatus(newRequest.id);
          if (status.status != 'pending') {
            print(
                "⚠️ Solicitud ${newRequest.id} no está pendiente, ignorando...");
            return;
          }
        } catch (e) {
          print("❌ Error verificando estado inicial: $e");
          return;
        }
        // Check if the request is already being shown
        if (_currentRequest != null && _currentRequest!.id == newRequest.id) {
          print("⚠️ Ya se está mostrando esta solicitud, ignorando...");
          return;
        }
        _isDialogShowing = true;
        timer.cancel();
        print("🎯 Mostrando diálogo de solicitud ID: ${newRequest.id}");
        setState(() {
          _currentRequest = newRequest;
          _driverStatus = DriverStatus.incomingRequest;
        });
        // NUEVO: Iniciar verificación de estado de la solicitud actual
        _startStatusChecker();
        final bool? accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              IncomingRequestDialog(serviceRequest: newRequest),
        );
        // NUEVO: Detener verificación de estado cuando el diálogo se cierra
        _stopStatusChecker();
        if (accepted == true) {
          _acceptRequest(newRequest.id);
        } else {
          _rejectRequest(newRequest.id);
        }
        _isDialogShowing = false;
        _startRequestChecker(); // Restart the checker after dialog closes
      }
    });
  }

  void _stopRequestChecker() {
    _requestCheckTimer?.cancel();
    _requestCheckTimer = null;
  }

  // NUEVO: Método para iniciar la verificación periódica del estado de la solicitud actual
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
        print(
            "🔍 Status check for request ${_currentRequest!.id}: ${status.status}");
        if (status.status == 'cancelled' && mounted) {
          print("⚠️ Solicitud cancelada, cerrando diálogo...");
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
          _startRequestChecker(); // Reiniciar la búsqueda de solicitudes
          timer.cancel();
        }
      } catch (e) {
        print("❌ Error verificando estado: $e");
      }
    });
  }

  // NUEVO: Método para detener la verificación de estado
  void _stopStatusChecker() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  void _acceptRequest(int requestId) async {
    setState(() {
      _driverStatus = DriverStatus.enRouteToUser;
      _isDialogShowing = false;
    });
    try {
      await TechnicianService.acceptRequest(requestId);
      _showErrorSnackbar('¡Solicitud aceptada! Dirígete al cliente.');
    } catch (e) {
      _showErrorSnackbar('Esta solicitud ya no está disponible.');
      setState(() {
        _driverStatus = DriverStatus.online;
        _currentRequest = null;
      });
      _startRequestChecker();
    }
  }

  void _rejectRequest(int requestId) async {
    try {
      await TechnicianService.rejectRequest(requestId);
      print("✅ Solicitud $requestId rechazada exitosamente");
    } catch (e) {
      print("❌ Error al rechazar en el servidor: $e");
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
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await _location.requestService();
    if (!serviceEnabled) {
      _showErrorSnackbar('Por favor, activa el servicio de ubicación.');
      _toggleOnlineStatus(false);
      return;
    }
    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        _showErrorSnackbar('El permiso de ubicación es necesario para operar.');
        _toggleOnlineStatus(false);
        return;
      }
    }
    _locationSubscription =
        _location.onLocationChanged.listen((LocationData newLocation) {
      if (mounted &&
          newLocation.latitude != null &&
          newLocation.longitude != null) {
        TechnicianService.updateLocation(
          newLocation.latitude!,
          newLocation.longitude!,
        );
        final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
        setState(() {
          _logic.animateCameraToPosition(newLatLng);
          _logic.updateUserMarker(newLatLng);
        });
      }
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    print("Rastreo de ubicación detenido.");
  }

// Agregar un refresh de ganancias después de completar un servicio
  void _updateServiceStatus() {
    setState(() {
      if (_driverStatus == DriverStatus.enRouteToUser) {
        _driverStatus = DriverStatus.onService;
      } else if (_driverStatus == DriverStatus.onService) {
        _driverStatus = DriverStatus.online;
        _currentRequest = null;
        // Recargar ganancias después de completar un servicio
        _loadEarnings();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _logic.initialCameraPosition,
            onMapCreated: (controller) =>
                _logic.mapController.complete(controller),
            markers: _logic.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          _buildDriverUI(),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildDriverUI() {
    return Stack(
      children: [
        _buildTopHeaderPanel(),
        if (_driverStatus == DriverStatus.incomingRequest)
          _buildIncomingRequestPanel(),
        if (_driverStatus == DriverStatus.enRouteToUser ||
            _driverStatus == DriverStatus.onService)
          _buildActiveServicePanel(),
      ],
    );
  }

  Widget _buildTopHeaderPanel() {
    bool isOnline = _driverStatus != DriverStatus.offline;

// Obtener valores reales o usar valores por defecto - Convertir a los tipos correctos
    final todayEarnings = double.tryParse(
            _earningsSummary?['today']?['earnings']?.toString() ?? '0') ??
        0.0;

    final todayServices = int.tryParse(
            _earningsSummary?['today']?['services']?.toString() ?? '0') ??
        0;

    final todayRating = double.tryParse(
            _earningsSummary?['today']?['rating']?.toString() ?? '5.0') ??
        5.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila principal: Estado y Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicador de estado
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? AppColors.accent
                                    : AppColors.error,
                                shape: BoxShape.circle,
                                boxShadow: isOnline
                                    ? [
                                        BoxShadow(
                                          color:
                                              AppColors.accent.withOpacity(0.6),
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
                                Text(
                                  isOnline ? 'EN LÍNEA' : 'DESCONECTADO',
                                  style: const TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                if (isOnline)
                                  Text(
                                    'Buscando solicitudes',
                                    style: TextStyle(
                                      color: AppColors.textOnPrimary
                                          .withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Switch
                      Transform.scale(
                        scale: 0.85,
                        child: Switch.adaptive(
                          value: isOnline,
                          onChanged: _toggleOnlineStatus,
                          activeColor: AppColors.accent,
                          activeTrackColor: AppColors.accent.withOpacity(0.3),
                          inactiveThumbColor: AppColors.lightGrey,
                          inactiveTrackColor:
                              AppColors.disabled.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),

                  // Estadísticas solo cuando está en línea
                  if (isOnline) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppColors.textOnPrimary.withOpacity(0.15),
                    ),
                    const SizedBox(height: 12),
                    // Fila de estadísticas con datos reales
                    Row(
                      children: [
                        _buildCompactStat(
                          icon: Icons.attach_money,
                          label: 'Hoy',
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
                          label: 'Servicios',
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
        ),
      ),
    );
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

  Widget _buildIncomingRequestPanel() {
    // Verificar que _currentRequest no sea null antes de usarla
    if (_currentRequest == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('NUEVA SOLICITUD DE RECARGA',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),
              const Text('5 min (2.3 km)',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Tesla Model 3 - Conector NACS',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _rejectRequest(_currentRequest!.id), // ✅ Con _
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[800]),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _acceptRequest(_currentRequest!.id), // ✅ Con _
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveServicePanel() {
    bool enRuta = _driverStatus == DriverStatus.enRouteToUser;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(enRuta ? 'DIRÍGETE AL CLIENTE' : 'SERVICIO EN CURSO',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text('Ana García'),
                subtitle: const Text('Av. Insurgentes Sur 123, CDMX'),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  onPressed: () {/* TODO: Implementar llamada */},
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(enRuta
                    ? Icons.navigation_outlined
                    : Icons.check_circle_outline),
                label: Text(enRuta ? 'Llegué al Sitio' : 'Finalizar Servicio'),
                onPressed: _updateServiceStatus,
                style: ElevatedButton.styleFrom(
                    backgroundColor: enRuta ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
