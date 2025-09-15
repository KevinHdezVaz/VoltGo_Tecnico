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
  String _currentInstruction = ''; // ✅ Inicializar vacío, se asignará desde AppLocalizations
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
    
    // Solo inicializar lo que NO depende del contexto
    _currentRequest = widget.serviceRequest;
    _activeServiceRequest = widget.serviceRequest;
    
    _destinationLocation = LatLng(
      widget.serviceRequest.requestLat,
      widget.serviceRequest.requestLng,
    );
    
    // NO usar AppLocalizations aquí
    _currentInstruction = ''; // Inicializar vacío temporalmente
    
    _getVehicleColor();
    _initializeAnimations();
  }

 @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Inicializar solo una vez cuando las dependencias estén listas
    if (!_hasInitialized) {
      _hasInitialized = true;
      
      // Ahora SÍ puedes usar AppLocalizations
      _currentInstruction = AppLocalizations.of(context).navigateToClient;
      
      // Inicializar el tracking
      _initializeTracking();
    }
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
    // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE setState
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);

        await _setupMarkers();
        await _getRoute();
        _startLocationTracking();
        _startRouteUpdates();
      }
    } catch (e) {
      print('❌ Error initializing tracking: $e');
      if (mounted) {
        _showErrorSnackbar(AppLocalizations.of(context).errorLoadingData);
      }
    } finally {
      // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          title: '${widget.serviceRequest.user?.name ?? AppLocalizations.of(context).client}',
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
    if (color == Colors.grey || color == Colors.black87) return BitmapDescriptor.hueBlue;
    
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
      // ✅ VERIFICAR SI EL WIDGET ESTÁ MONTADO ANTES DE CONTINUAR
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
          infoWindow: InfoWindow(title: AppLocalizations.of(context).technician),
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
            Expanded(child: Text(AppLocalizations.of(context).technicianArrivedTitle)),
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

  @override
  void dispose() {
    // ✅ CANCELAR TODOS LOS TIMERS Y ANIMACIONES ANTES DE HACER DISPOSE
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
          GoogleMap(
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              if (_currentLocation != null) {
                _centerMapOnCurrentLocation();
              }
              String mapStyle =
                  await rootBundle.loadString('assets/map_style.json');
              controller.setMapStyle(mapStyle);
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? _destinationLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 120,
              bottom: 200,
            ),
          ),
          _buildNavigationHeader(),
          _buildBottomPanel(),
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
                  value: '$_estimatedTimeMinutes ${AppLocalizations.of(context).min}',
                ),
                _buildNavInfo(
                  icon: Icons.social_distance,
                  label: AppLocalizations.of(context).distance,
                  value: '${_distanceToDestination.toStringAsFixed(1)} km',
                ),
                _buildNavInfo(
                  icon: Icons.speed,
                  label: 'Velocidad', // ✅ Fallback ya que no está en AppLocalizations
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
            final unreadCount = chatProvider.getUnreadForService(widget.serviceRequest.id);
            
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
        _showErrorSnackbar(AppLocalizations.of(context).errorRefreshingServiceData);
      }
    }
  }

  void _openChat() async {
    HapticFeedback.lightImpact();

    print('🔍 Abriendo chat para servicio: ${widget.serviceRequest.id}');
    print('📱 Usuario: ${widget.serviceRequest.user?.name ?? AppLocalizations.of(context).client}');

    final chatProvider = Provider.of<ChatNotificationProvider>(context, listen: false);
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
            _showErrorSnackbar(AppLocalizations.of(context).couldNotOpenPhoneApp);
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
                AppLocalizations.of(context).pleaseWaitMoment,
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

Future<BitmapDescriptor> _createCarIcon(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(120, 120);

  final paint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);

  final borderPaint = Paint()
    ..color = Colors.grey.shade300
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 1, borderPaint);

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