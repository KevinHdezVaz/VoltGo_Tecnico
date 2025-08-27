// ✅ PASO 1: Crear la pantalla de seguimiento en tiempo real
// Archivo: lib/ui/screens/RealTimeTrackingScreen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:Voltgo_app/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_app/data/services/ServiceRequestService.dart';
import 'package:Voltgo_app/ui/MenuPage/findATechnician/ServiceWorkScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/services/TechnicianService.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class RealTimeTrackingScreen extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  final VoidCallback? onServiceComplete;

  const RealTimeTrackingScreen({
    Key? key,
    required this.serviceRequest,
    this.onServiceComplete,
  }) : super(key: key);

  @override
  State<RealTimeTrackingScreen> createState() => _RealTimeTrackingScreenState();
}

class _RealTimeTrackingScreenState extends State<RealTimeTrackingScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Location _location = Location();
  Timer? _locationTimer;
  Timer? _routeTimer;

  ServiceRequestModel? _currentRequest;

  // Ubicaciones
  ServiceRequestModel? _activeServiceRequest;

  LatLng? _currentLocation;
  late LatLng _destinationLocation;

  // Marcadores y rutas
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Información de navegación
  double _distanceToDestination = 0.0;
  int _estimatedTimeMinutes = 0;
  String _currentInstruction = 'Iniciando navegación...';
  double _currentSpeed = 0.0;

  // Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Estados
  bool _isLoading = true;
  bool _hasArrivedAtDestination = false;

  @override
  void initState() {
    super.initState();

    // ✅ CORREGIDO: Inicializar _currentRequest con los datos del widget
    _currentRequest = widget.serviceRequest;
    _activeServiceRequest = widget.serviceRequest;

    _destinationLocation = LatLng(
      widget.serviceRequest.requestLat,
      widget.serviceRequest.requestLng,
    );

    _initializeAnimations();
    _initializeTracking();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeTracking() async {
    setState(() => _isLoading = true);

    try {
      // Obtener ubicación actual
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);

        // Configurar marcadores iniciales
        await _setupMarkers();

        // Obtener ruta inicial
        await _getRoute();

        // Iniciar seguimiento en tiempo real
        _startLocationTracking();
        _startRouteUpdates();
      }
    } catch (e) {
      print('❌ Error initializing tracking: $e');
      _showErrorSnackbar('Error al inicializar seguimiento');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupMarkers() async {
    if (_currentLocation == null) return;

    _markers = {
      // Marcador del técnico (ubicación actual)
      Marker(
        markerId: const MarkerId('technician'),
        position: _currentLocation!,
        icon: await _createCustomMarker('T', AppColors.primary),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ),

      // Marcador del cliente (destino)
      Marker(
        markerId: const MarkerId('client'),
        position: _destinationLocation,
        icon: await _createCustomMarker('C', AppColors.error),
        infoWindow: InfoWindow(
          title: 'Cliente: ${widget.serviceRequest.user?.name ?? 'Cliente'}',
          snippet: 'Destino del servicio',
        ),
      ),
    };

    setState(() {});
  }

  Future<BitmapDescriptor> _createCustomMarker(String text, Color color) async {
    // Crear un marcador personalizado con texto
    return BitmapDescriptor.defaultMarkerWithHue(
      color == AppColors.primary
          ? BitmapDescriptor.hueBlue
          : BitmapDescriptor.hueRed,
    );
  }

  Future<void> _getRoute() async {
    if (_currentLocation == null) return;

    try {
      // Aquí puedes integrar Google Directions API
      // Por ahora, creamos una línea directa
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_currentLocation!, _destinationLocation],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };

      // Calcular distancia y tiempo
      _calculateDistanceAndTime();

      setState(() {});
    } catch (e) {
      print('❌ Error getting route: $e');
    }
  }

  void _calculateDistanceAndTime() {
    if (_currentLocation == null) return;

    // Calcular distancia usando fórmula haversine
    _distanceToDestination = _calculateDistance(
      _currentLocation!,
      _destinationLocation,
    );

    // Estimar tiempo (velocidad promedio 30 km/h en ciudad)
    _estimatedTimeMinutes = (_distanceToDestination / 30 * 60).round();

    // Verificar si ha llegado al destino (dentro de 100 metros)
    if (_distanceToDestination < 0.1 && !_hasArrivedAtDestination) {
      _handleArrivalAtDestination();
    }

    // Actualizar instrucción
    _updateInstruction();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  void _updateInstruction() {
    if (_distanceToDestination < 0.1) {
      _currentInstruction = '¡Has llegado al destino!';
    } else if (_distanceToDestination < 0.5) {
      _currentInstruction = 'Estás muy cerca del cliente';
    } else if (_distanceToDestination < 1.0) {
      _currentInstruction = 'Te acercas al destino';
    } else {
      _currentInstruction = 'Continúa hacia el cliente';
    }
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final locationData = await _location.getLocation();
        if (locationData.latitude != null && locationData.longitude != null) {
          final newLocation =
              LatLng(locationData.latitude!, locationData.longitude!);

          // Actualizar ubicación actual
          _currentLocation = newLocation;
          _currentSpeed = locationData.speed ?? 0.0;

          // Actualizar marcador del técnico
          _updateTechnicianMarker(newLocation);

          // Enviar ubicación al servidor
          TechnicianService.updateLocation(
            locationData.latitude!,
            locationData.longitude!,
          );

          // Recalcular distancia y tiempo
          _calculateDistanceAndTime();

          // Centrar mapa en ubicación actual
          _centerMapOnCurrentLocation();
        }
      } catch (e) {
        print('❌ Error tracking location: $e');
      }
    });
  }

  void _updateTechnicianMarker(LatLng newLocation) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'technician');
      _markers.add(
        Marker(
          markerId: const MarkerId('technician'),
          position: newLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );
    });
  }

  void _startRouteUpdates() {
    _routeTimer?.cancel();
    _routeTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // Actualizar ruta cada 10 segundos
      await _getRoute();
    });
  }

  void _centerMapOnCurrentLocation() {
    if (_mapController == null || _currentLocation == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation!,
          zoom: 16.0,
          tilt: 45.0,
          bearing: 0.0,
        ),
      ),
    );
  }

  void _handleArrivalAtDestination() {
    if (_hasArrivedAtDestination) return;

    setState(() => _hasArrivedAtDestination = true);

    // Vibración
    HapticFeedback.heavyImpact();

    // Mostrar diálogo de llegada
    _showArrivalDialog();
  }

  void _showArrivalDialog() {
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
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on, color: Colors.green, size: 30),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Has llegado!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Has llegado a la ubicación del cliente.',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Contacta al cliente para coordinar el servicio de recarga.',
                style: GoogleFonts.inter(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _markServiceAsOnSite();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child:
                Text('Iniciar Servicio', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markServiceAsOnSite() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ServiceWorkScreen(
          serviceRequest: widget.serviceRequest,
          onServiceComplete: null, // Ya no necesitas callback
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _routeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _centerMapOnCurrentLocation();
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? _destinationLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false, // Usamos nuestro marcador personalizado
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 120,
              bottom: 200,
            ),
          ),

          // Header con información de navegación
          _buildNavigationHeader(),

          // Panel inferior con controles
          _buildBottomPanel(),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.brandBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Fila superior con botón atrás y título
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    'Navegando hacia el cliente',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance visual
              ],
            ),
            const SizedBox(height: 8),

            // Información de navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavInfo(
                  icon: Icons.access_time,
                  label: 'Tiempo',
                  value: '$_estimatedTimeMinutes min',
                ),
                _buildNavInfo(
                  icon: Icons.social_distance,
                  label: 'Distancia',
                  value: '${_distanceToDestination.toStringAsFixed(1)} km',
                ),
                _buildNavInfo(
                  icon: Icons.speed,
                  label: 'Velocidad',
                  value: '${(_currentSpeed * 3.6).toStringAsFixed(0)} km/h',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Instrucción actual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(
                            0.2 + (_pulseAnimation.value * 0.3),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.navigation,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentInstruction,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        widget.serviceRequest.user?.name.isNotEmpty == true
                            ? widget.serviceRequest.user!.name[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.serviceRequest.user?.name ??
                                'Cliente', // ✅ widget.serviceRequest
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Servicio de recarga solicitado',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ✅ BOTONES SEPARADOS - CORREGIDO
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botón de llamar
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _callClient(),
            icon: Icon(Icons.phone, size: 18),
            label:
                Text('Llamar', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: BorderSide(color: AppColors.success),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Botón de mensaje
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openChat,
            icon: Icon(Icons.message, size: 18),
            label:
                Text('Mensaje', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: BorderSide(color: AppColors.info),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

// ✅ MÉTODOS CORREGIDOS EN RealTimeTrackingScreen

  void _refreshServiceData() async {
    try {
      // ✅ CORREGIDO: Usar widget.serviceRequest que SÍ tiene datos
      final updatedRequest = await ServiceRequestService.getRequestStatus(
          widget.serviceRequest.id);
      setState(() {
        // Actualizar las variables internas si las necesitas
        _currentRequest = updatedRequest;
        _activeServiceRequest = updatedRequest;
      });
    } catch (e) {
      print('Error refreshing service data: $e');
    }
  }

  void _openChat() async {
    // ✅ CORREGIDO: Usar widget.serviceRequest en lugar de _currentRequest
    // widget.serviceRequest SIEMPRE tiene datos porque se pasa desde la pantalla anterior

    HapticFeedback.lightImpact();

    print('🔍 Abriendo chat para servicio: ${widget.serviceRequest.id}');
    print('📱 Usuario: ${widget.serviceRequest.user?.name ?? 'Desconocido'}');

    // Navegar a la pantalla de chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceChatScreen(
          serviceRequest: widget.serviceRequest, // ✅ USAR widget.serviceRequest
          userType: 'technician',
        ),
      ),
    );
  }

// ✅ Función corregida y habilitada para llamar
  void _callClient() async {
    // La función ahora es 'async'
    final clientPhone = widget.serviceRequest.user?.phone;

    if (clientPhone != null && clientPhone.isNotEmpty) {
      // Prepara el URI para la llamada usando el esquema 'tel:'
      final Uri phoneUri = Uri(scheme: 'tel', path: clientPhone);

      try {
        // Intenta abrir la app de teléfono con el número
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          // Si no se puede, muestra un error
          _showErrorSnackbar('No se pudo abrir la aplicación de teléfono');
        }
      } catch (e) {
        _showErrorSnackbar('Error al intentar llamar: $e');
      }
    } else {
      _showErrorSnackbar('No hay número de teléfono disponible');
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Configurando navegación...',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
