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
  // Posición inicial del mapa (Ciudad de México por defecto)
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(19.432608, -99.133209),
    zoom: 13.0,
  );

  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _centerMapOnUserLocation();
  }

  Future<void> _centerMapOnUserLocation() async {
    final location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final locationData = await location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(locationData.latitude!, locationData.longitude!),
          15.0,
        ),
      );
    }
  }

  void _onConfirmLocation() async {
    if (_pickedLocation == null) return;
    setState(() => _isLoading = true);

    try {
      // Convertir coordenadas a una dirección legible
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        // Formateamos la dirección para que sea clara
        final address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        if (mounted) {
          Navigator.of(context).pop(address);
        }
      }
    } catch (e) {
      // Manejo de errores
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No se pudo obtener la dirección. Intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu ubicación de base'),
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
            // Controles nativos desactivados
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // =======================================================
          // NUEVOS BOTONES PERSONALIZADOS
          // =======================================================
          Positioned(
            top: 16.0,
            right: 16.0,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "btn_gps",
                  onPressed: _centerMapOnUserLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.gps_fixed, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.small(
                  heroTag: "btn_zoom_in",
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black54),
                ),
                const SizedBox(height: 8),
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

          // Pin/Marcador en el centro
          const Icon(Icons.location_pin, size: 50, color: Colors.red),

          // Botón de confirmar en la parte inferior
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              // ... (tu botón de confirmar se queda igual)
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.check, color: Colors.white),
              label: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirmar Ubicación',
                      style: TextStyle(color: Colors.white),
                    ),
              onPressed: _pickedLocation == null || _isLoading
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
