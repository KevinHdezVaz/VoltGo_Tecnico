// map_picker_screen.dart

import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({Key? key}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Initial map position (Mexico City by default)
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(19.432608, -99.133209),
    zoom: 13.0,
  );

  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _isLoadingConfirm = false; // For the confirm button
  bool _isCenteringLocation = false; // For the GPS button

 @override
void initState() {
  super.initState();
  // No llamar _centerMapOnUserLocation() inmediatamente
  // Esperar a que el widget esté completamente construido
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _centerMapOnUserLocation();
  });
}

 Future<void> _centerMapOnUserLocation() async {
  setState(() => _isCenteringLocation = true);

  try {
    final location = loc.Location();
    
    // Verificar si el servicio está habilitado
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location service not enabled');
      }
    }

    // Verificar permisos de forma más robusta
    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        throw Exception('Location permission denied');
      }
      if (permissionGranted == loc.PermissionStatus.deniedForever) {
        throw Exception('Location permission permanently denied');
      }
    }

    // Solo obtener ubicación si tenemos permisos
    if (permissionGranted == loc.PermissionStatus.granted) {
      final locationData = await location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        if (_mapController != null && mounted) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(locationData.latitude!, locationData.longitude!),
              15.0,
            ),
          );
        }
      }
    }
  } catch (e) {
    debugPrint('Error al obtener la ubicación: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo obtener tu ubicación: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isCenteringLocation = false);
    }
  }
}

  void _onConfirmLocation() async {
    if (_pickedLocation == null) return;
    setState(() => _isLoadingConfirm = true);

    try {
      // Convert coordinates to a readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        // We format the address to be clear
        final address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        if (mounted) {
          Navigator.of(context).pop(address);
        }
      }
    } catch (e) {
      // Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not get the address. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingConfirm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Base Location'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              setState(() {
                _pickedLocation = position.target;
              });
            },
            myLocationEnabled: true,
            // Native controls disabled to use custom ones
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // =======================================================
          // CUSTOM MAP CONTROL BUTTONS
          // =======================================================
          Positioned(
            top: 16.0,
            right: 16.0,
            child: Column(
              children: [
                // GPS Center Button
                FloatingActionButton.small(
                  heroTag: "btn_gps",
                  onPressed: _isCenteringLocation ? null : _centerMapOnUserLocation,
                  backgroundColor: Colors.white,
                  child: _isCenteringLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.gps_fixed, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                // Zoom In Button
                FloatingActionButton.small(
                  heroTag: "btn_zoom_in",
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                // Zoom Out Button
                FloatingActionButton.small(
                  heroTag: "btn_zoom_out",
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black54),
                ),
              ],
            ),
          ),
          // =======================================================

          // Pin/Marker in the center
          const Icon(Icons.location_pin, size: 50, color: Colors.red),

          // Confirm button at the bottom
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              icon: _isLoadingConfirm
                  ? const SizedBox.shrink()
                  : const Icon(Icons.check, color: Colors.white),
              label: _isLoadingConfirm
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirm Location',
                      style: TextStyle(color: Colors.white),
                    ),
              onPressed: _pickedLocation == null || _isLoadingConfirm
                  ? null
                  : _onConfirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                elevation: 8,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          )
        ],
      ),
    );
  }
}