// ✅ PANTALLA DE SEGUIMIENTO EN TIEMPO REAL - CORREGIDA PARA EVITAR setState DESPUÉS DE DISPOSE
// Archivo: lib/ui/screens/RealTimeTrackingScreen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:Voltgo_app/data/services/ChatNotificationProvider.dart';
import 'package:Voltgo_app/data/services/ServiceChatScreen.dart';
import 'package:Voltgo_app/data/services/ServiceRequestService.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
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
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

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
  ServiceRequestModel? _activeServiceRequest;
  bool _locationPermissionGranted = false; // ✅ NUEVO
  bool _mapReady = false; // ✅ NUEVO


  // Ubicaciones
  LatLng? _currentLocation;
  late LatLng _destinationLocation;

  // Marcadores y rutas
  Set<Marker> _markers = {};
  Color _vehicleColor = Colors.blue; // Color por defecto

  Set<Polyline> _polylines = {};

  // Información de navegación
  double _distanceToDestination = 0.0;
  int _estimatedTimeMinutes = 0;
  String _currentInstruction =
      ''; // ✅ Inicializar vacío, se asignará desde AppLocalizations
  double _currentSpeed = 0.0;

  // Animaciones
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Estados
  bool _hasInitialized = false;
  bool _isLoading = true;
  bool _hasArrivedAtDestination = false;

    @override
  void initState() {
    super.initState();

    // Solo inicializar lo básico
    _currentRequest = widget.serviceRequest;
    _activeServiceRequest = widget.serviceRequest;

    _destinationLocation = LatLng(
      widget.serviceRequest.requestLat,
      widget.serviceRequest.requestLng,
    );

    _initializeAnimations();
    
    // ✅ INICIALIZAR CON TIMEOUT
    _initializeWithTimeout();
  }
 
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ SOLO asignar localización aquí, no inicializar de nuevo
    if (!_hasInitialized) {
      _hasInitialized = true;
      _currentInstruction = AppLocalizations.of(context).navigateToClient;
    }
  }



Future<void> _initializeWithTimeout() async {
    try {
      await Future.wait([
        _initializeTracking(),
        Future.delayed(const Duration(seconds: 8)) // ✅ Timeout máximo de 8 segundos
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Timeout en inicialización, continuando con valores por defecto');
          _handleInitializationTimeout();
          return [null, null];
        },
      );
    } catch (e) {
      print('❌ Error en inicialización: $e');
      _handleInitializationError(e);
    }
  }


 void _handleInitializationTimeout() {
    if (!mounted) return;
    
    print('⚠️ Inicialización tardó demasiado, usando configuración básica');
    
    setState(() {
      _isLoading = false;
      _currentInstruction = 'Navigate to client location';
      // Configurar marcadores básicos sin location
      _setupBasicMarkers();
    });
  }


void _handleInitializationError(dynamic error) {
    if (!mounted) return;
    
    print('❌ Error fatal en inicialización: $error');
    
    setState(() {
      _isLoading = false;
      _currentInstruction = 'Error loading navigation';
    });
    
    _showErrorSnackbar('Error setting up navigation. Please try again.');
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

  Future<void> _getVehicleColor() async {
    try {
      final profile = await TechnicianService.getProfile();

      if (profile['technician_profile'] != null &&
          profile['technician_profile']['vehicle_details'] != null) {
        final vehicleDetails = profile['technician_profile']['vehicle_details'];
        String? colorName;

        if (vehicleDetails is String) {
          try {
            final decoded = jsonDecode(vehicleDetails);
            colorName = decoded['color'];
          } catch (e) {
            print('Error parsing vehicle_details: $e');
          }
        } else if (vehicleDetails is Map) {
          colorName = vehicleDetails['color'];
        }

        if (colorName != null && colorName.isNotEmpty) {
          // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE setState
          if (mounted) {
            setState(() {
              _vehicleColor = _getColorFromName(colorName!);
            });
          }
          print('Color del vehículo obtenido: $colorName -> $_vehicleColor');
        }
      }
    } catch (e) {
      print('Error obteniendo color del vehículo: $e');
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'rojo':
      case 'red':
        return Colors.red;
      case 'azul':
      case 'blue':
        return Colors.blue;
      case 'verde':
      case 'green':
        return Colors.green;
      case 'amarillo':
      case 'yellow':
        return Colors.yellow;
      case 'negro':
      case 'black':
        return Colors.black87;
      case 'blanco':
      case 'white':
        return Colors.grey[300]!;
      case 'gris':
      case 'gray':
      case 'grey':
        return Colors.grey;
      case 'naranja':
      case 'orange':
        return Colors.orange;
      case 'morado':
      case 'purple':
        return Colors.purple;
      case 'rosa':
      case 'pink':
        return Colors.pink;
      case 'café':
      case 'brown':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

Future<void> _initializeTracking() async {
    print('🚀 Iniciando _initializeTracking...');
    
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // ✅ PASO 1: Verificar permisos de ubicación (con timeout corto)
      final bool permissionGranted = await _checkLocationPermission().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⏰ Timeout en permisos de ubicación');
          return false;
        },
      );

      if (!permissionGranted) {
        print('❌ Permisos de ubicación no concedidos');
        _handleLocationPermissionDenied();
        return;
      }

      // ✅ PASO 2: Obtener ubicación actual (con timeout)
      LocationData? locationData;
      try {
  locationData = await _location.getLocation().timeout(
    const Duration(seconds: 5),
    onTimeout: () => throw TimeoutException('Location timeout', const Duration(seconds: 5)),
  );
} on TimeoutException {
  print('⏰ Timeout obteniendo ubicación');
  locationData = null;
} 
catch (e) {
        print('❌ Error obteniendo ubicación: $e');
        locationData = null;
      }

      if (locationData?.latitude != null && locationData?.longitude != null) {
        _currentLocation = LatLng(locationData!.latitude!, locationData.longitude!);
        print('📍 Ubicación obtenida: $_currentLocation');
      } else {
        print('⚠️ No se pudo obtener ubicación, usando ubicación de destino');
        _currentLocation = _destinationLocation;
      }

      // ✅ PASO 3: Configurar marcadores (no esperar)
      _setupMarkersAsync();

      // ✅ PASO 4: Obtener color del vehículo (en background)
      _getVehicleColorAsync();

      // ✅ PASO 5: Calcular ruta
      await _getRoute();

      // ✅ PASO 6: Iniciar servicios
      if (_currentLocation != null) {
        _startLocationTracking();
        _startRouteUpdates();
      }

      print('✅ _initializeTracking completado exitosamente');

    } catch (e) {
      print('❌ Error en _initializeTracking: $e');
      _handleInitializationError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  

    // ✅ NUEVO: Verificar permisos de ubicación de forma robusta
  Future<bool> _checkLocationPermission() async {
    try {
      // Verificar si el servicio está habilitado
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('❌ Servicio de ubicación no habilitado');
          return false;
        }
      }

      // Verificar permisos
      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          print('❌ Permisos de ubicación denegados');
          return false;
        }
      }

      _locationPermissionGranted = true;
      return true;
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }

   void _handleLocationPermissionDenied() {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _currentInstruction = 'Location permission required';
    });
    
    _showErrorSnackbar('Location permission is required for navigation');
    
    // Configurar marcadores básicos sin ubicación
    _setupBasicMarkers();
  }


  void _setupMarkersAsync() {
    _setupMarkers().catchError((e) {
      print('⚠️ Error configurando marcadores: $e');
      _setupBasicMarkers();
    });
  }



 void _setupBasicMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('client'),
        position: _destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.serviceRequest.user?.name ?? 'Client',
          snippet: 'Destination',
        ),
      ),
    };

    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('technician'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your location'),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }


void _getVehicleColorAsync() {
    _getVehicleColor().catchError((e) {
      print('⚠️ Error obteniendo color del vehículo: $e');
      // Continuar con color por defecto
    });
  }


    Future<void> _setupMarkers() async {
    if (_currentLocation == null) return;

    _markers = {
      Marker(
        markerId: const MarkerId('technician'),
        position: _currentLocation!,
        icon: await _createCarIcon(Colors.blue),
        infoWindow: InfoWindow(title: AppLocalizations.of(context).technician),
      ),
      Marker(
        markerId: const MarkerId('client'),
        position: _destinationLocation,
        icon: await _createCarIcon(Colors.red),
        infoWindow: InfoWindow(
          title:
              '${widget.serviceRequest.user?.name ?? AppLocalizations.of(context).client}',
          snippet: AppLocalizations.of(context).chargeServiceRequested,
        ),
      ),
    };

    // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE setState
    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _createTechnicianIcon() async {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  Future<BitmapDescriptor> _createVehicleIcon() async {
    final hue = _colorToHue(_vehicleColor);
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  double _colorToHue(Color color) {
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.yellow) return BitmapDescriptor.hueYellow;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    if (color == Colors.pink) return BitmapDescriptor.hueRose;
    if (color == Colors.grey || color == Colors.black87)
      return BitmapDescriptor.hueBlue;

    HSVColor hsv = HSVColor.fromColor(color);
    return hsv.hue;
  }

  Future<BitmapDescriptor> _createElectricCarIcon() async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/electric_car_marker.png',
      );
    } catch (e) {
      print('No se pudo cargar el ícono personalizado, usando por defecto');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(String text, Color color) async {
    return BitmapDescriptor.defaultMarkerWithHue(
      color == AppColors.primary
          ? BitmapDescriptor.hueBlue
          : BitmapDescriptor.hueRed,
    );
  }

  Future<void> _getRoute() async {
    if (_currentLocation == null) return;

    try {
      _polylines = {};
      _calculateDistanceAndTime();
      // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE setState
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error getting route: $e');
    }
  }

  void _calculateDistanceAndTime() {
    if (_currentLocation == null) return;

    _distanceToDestination = _calculateDistance(
      _currentLocation!,
      _destinationLocation,
    );

    _estimatedTimeMinutes = (_distanceToDestination / 30 * 60).round();

    if (_distanceToDestination < 0.1 && !_hasArrivedAtDestination) {
      _handleArrivalAtDestination();
    }

    _updateInstruction();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;
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
      _currentInstruction = AppLocalizations.of(context).technicianArrivedTitle;
    } else if (_distanceToDestination < 0.5) {
      _currentInstruction = AppLocalizations.of(context).technicianOnWay;
    } else if (_distanceToDestination < 1.0) {
      _currentInstruction = AppLocalizations.of(context).technicianEnRoute;
    } else {
      _currentInstruction = AppLocalizations.of(context).navigateToClient;
    }
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final locationData = await _location.getLocation();
        if (locationData.latitude != null && locationData.longitude != null) {
          final newLocation =
              LatLng(locationData.latitude!, locationData.longitude!);

          _currentLocation = newLocation;
          _currentSpeed = locationData.speed ?? 0.0;

          _updateTechnicianMarker(newLocation);

          TechnicianService.updateLocation(
            locationData.latitude!,
            locationData.longitude!,
          );

          _calculateDistanceAndTime();
          _centerMapOnCurrentLocation();
        }
      } catch (e) {
        print('❌ Error tracking location: $e');
      }
    });
  }

  void _updateTechnicianMarker(LatLng newLocation) async {
    // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE setState
    if (!mounted) return;

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'technician');
    });

    final technicianCarIcon = await _createCarIcon(Colors.blue);

    // ✅ VERIFICAR NUEVAMENTE SI EL WIDGET ESTÁ MONTADO DESPUÉS DE LA OPERACIÓN ASYNC
    if (!mounted) return;

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('technician'),
          position: newLocation,
          icon: technicianCarIcon,
          infoWindow:
              InfoWindow(title: AppLocalizations.of(context).technician),
        ),
      );
    });
  }

  void _startRouteUpdates() {
    _routeTimer?.cancel();
    _routeTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE CONTINUAR
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    if (_hasArrivedAtDestination || !mounted) return;

    setState(() => _hasArrivedAtDestination = true);

    HapticFeedback.heavyImpact();
    _showArrivalDialog();
  }

  void _showArrivalDialog() {
    // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE MOSTRAR EL DIÁLOGO
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
            Expanded(
                child:
                    Text(AppLocalizations.of(context).technicianArrivedTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).technicianArrivedMessage,
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
                AppLocalizations.of(context).contactTechnician,
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
            child: Text(
              AppLocalizations.of(context).arrivedAtSite,
              style: TextStyle(color: Colors.white),
            ),
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
          onServiceComplete: null,
        ),
      ),
    );
  }

  // ✅ MÉTODO MEJORADO: dispose
  @override
  void dispose() {
    print('🗑️ Disposing RealTimeTrackingScreen...');
    
    // Cancelar timers
    _locationTimer?.cancel();
    _routeTimer?.cancel();
    
    // Dispose animations
    _pulseController.dispose();
    
    // Limpiar controller
    _mapController = null;
    
    super.dispose();
  }



@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ GOOGLE MAP CON MANEJO DE ERRORES
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? _destinationLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            // ✅ CONFIGURACIÓN ROBUSTA
            compassEnabled: true,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 120,
              bottom: 120,
            ),
          ),
          
          _buildNavigationHeader(),
          _buildBottomPanel(),
          
          // ✅ LOADING OVERLAY MEJORADO
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

 Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
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
                'Setting up navigation...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              
              // ✅ BOTÓN DE ESCAPE DESPUÉS DE 5 SEGUNDOS
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = false;
                  });
                  _setupBasicMarkers();
                },
                child: Text(
                  'Continue without full setup',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
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
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).navigateToClient,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavInfo(
                  icon: Icons.access_time,
                  label: AppLocalizations.of(context).time,
                  value:
                      '$_estimatedTimeMinutes ${AppLocalizations.of(context).min}',
                ),
                _buildNavInfo(
                  icon: Icons.social_distance,
                  label: AppLocalizations.of(context).distance,
                  value: '${_distanceToDestination.toStringAsFixed(1)} km',
                ),
                _buildNavInfo(
                  icon: Icons.speed,
                  label:
                      'Velocidad', // ✅ Fallback ya que no está en AppLocalizations
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


Future<void> _onMapCreated(GoogleMapController controller) async {
    try {
      _mapController = controller;
      _mapReady = true;
      
      if (_currentLocation != null) {
        _centerMapOnCurrentLocation();
      }
      
      // Cargar estilo del mapa
      try {
        String mapStyle = await rootBundle.loadString('assets/map_style.json');
        await controller.setMapStyle(mapStyle);
        print('✅ Estilo del mapa aplicado');
      } catch (e) {
        print('⚠️ No se pudo cargar el estilo del mapa: $e');
        // Continuar sin estilo personalizado
      }
      
      print('✅ Google Maps inicializado correctamente');
    } catch (e) {
      print('❌ Error en onMapCreated: $e');
    }
  }


// ✅ REEMPLAZA tu _buildBottomPanel actual con esta versión arrastrable
Widget _buildBottomPanel() {
  return DraggableScrollableSheet(
    initialChildSize: 0.5, // ✅ Inicia al 35% de la pantalla
    minChildSize: 0.15, // ✅ Mínimo 15% (solo instrucción visible)
    maxChildSize: 0.6, // ✅ Máximo 70% para ver bien el mapa
    snap: true, // ✅ Se pega a posiciones específicas
    snapSizes: [0.15, 0.35, 0.6], // ✅ Posiciones donde se "pega"
    builder: (context, scrollController) {
      return Container(
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
        child: Column(
          children: [
            // ✅ HANDLE PARA ARRASTRAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            
            // ✅ CONTENIDO SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ✅ INSTRUCCIÓN ACTUAL (siempre visible)
                    Container(
                      width: double.infinity,
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
                    
                    // ✅ INFORMACIÓN ADICIONAL (visible al expandir)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade700),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.route,
                            color: Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Head to the customer, follow these routes to arrive faster.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // ✅ BOTÓN DE NAVEGACIÓN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.navigation, size: 16),
                        label: Text(
                          AppLocalizations.of(context).openInMaps,
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        onPressed: _showNavigationOptions,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ✅ CARD DEL CLIENTE
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
                                  widget.serviceRequest.user?.name ?? AppLocalizations.of(context).client,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context).chargeServiceRequested,
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
                    
                    // ✅ BOTONES DE ACCIÓN
                    _buildActionButtons(),
                    
                    // ✅ ESPACIO FINAL PARA SCROLL
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
 
// ✅ WIDGET HELPER PARA INFORMACIÓN DEL VIAJE
Widget _buildTripInfo({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Column(
    children: [
      Icon(icon, color: AppColors.primary, size: 16),
      const SizedBox(height: 4),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _callClient(),
            icon: Icon(Icons.phone, size: 18),
            label: Text(
              AppLocalizations.of(context).call,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
        Consumer<ChatNotificationProvider>(
          builder: (context, chatProvider, child) {
            final unreadCount =
                chatProvider.getUnreadForService(widget.serviceRequest.id);

            return Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openChat,
                      icon: Icon(Icons.message, size: 18),
                      label: Text(
                        AppLocalizations.of(context).chat,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
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
            subtitle: localizations.navigationWithTraffic,
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
            subtitle: localizations.optimizedRoutes,
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
              localizations.cancel,
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

  void _refreshServiceData() async {
    try {
      final updatedRequest = await ServiceRequestService.getRequestStatus(
          widget.serviceRequest.id);

      // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE setState
      if (mounted) {
        setState(() {
          _currentRequest = updatedRequest;
          _activeServiceRequest = updatedRequest;
        });
      }
    } catch (e) {
      print('Error refreshing service data: $e');
      if (mounted) {
        _showErrorSnackbar(
            AppLocalizations.of(context).errorRefreshingServiceData);
      }
    }
  }

  void _openChat() async {
    HapticFeedback.lightImpact();

    print('🔍 Abriendo chat para servicio: ${widget.serviceRequest.id}');
    print(
        '📱 Usuario: ${widget.serviceRequest.user?.name ?? AppLocalizations.of(context).client}');

    final chatProvider =
        Provider.of<ChatNotificationProvider>(context, listen: false);
    await chatProvider.markServiceAsRead(widget.serviceRequest.id);

    // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE NAVEGAR
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceChatScreen(
            serviceRequest: widget.serviceRequest,
            userType: 'technician',
          ),
        ),
      ).then((_) {
        chatProvider.forceRefresh();
      });
    }
  }

  void _callClient() async {
    final clientPhone = widget.serviceRequest.user?.phone;

    if (clientPhone != null && clientPhone.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: clientPhone);

      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          if (mounted) {
            _showErrorSnackbar(
                AppLocalizations.of(context).couldNotOpenPhoneApp);
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackbar(AppLocalizations.of(context).errorMakingCall);
        }
      }
    } else {
      if (mounted) {
        _showErrorSnackbar(AppLocalizations.of(context).noPhoneNumberAvailable);
      }
    }
  }

  Future<void> _launchGoogleMaps(
      double lat, double lng, String destination) async {
    try {
      // URL para abrir Google Maps con navegación
      final String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';

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

 

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

Future<BitmapDescriptor> _createCarIcon(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(120, 120);

  final paint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), size.width / 2, paint);

  final borderPaint = Paint()
    ..color = Colors.grey.shade300
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), size.width / 2 - 1, borderPaint);

  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.directions_car.codePoint),
      style: TextStyle(
        fontSize: 110,
        fontFamily: Icons.directions_car.fontFamily,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final uint8List = byteData!.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(uint8List);
}
