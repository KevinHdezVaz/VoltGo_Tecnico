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
            myLocationButtonEnabled: true,
          ),
          // Pin/Marcador en el centro
          const Icon(Icons.location_pin, size: 50, color: Colors.red),

          // Botón de confirmar en la parte inferior
          Positioned(
            // Posicionamos el botón con márgenes a los lados para que se centre y se estire
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
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
                // 1. Color de fondo y de texto/ícono
                backgroundColor:
                    AppColors.brandBlue, // Un color fuerte de tu marca
                foregroundColor: Colors.white, // Color para el texto y el ícono

                // 2. Sombra más pronunciada para dar efecto de elevación
                elevation: 8,

                // 3. Texto más legible
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),

                // 4. Padding y forma (ya los tenías, se mantienen)
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                // 5. Tamaño mínimo para asegurar que no sea demasiado pequeño
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          )
        ],
      ),
    );
  }
}
