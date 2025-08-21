import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardLogic {
  // --- ESTADO DEL MAPA ---
  final Completer<GoogleMapController> mapController = Completer();
  final Set<Marker> markers = {};

  // Posición inicial por defecto, se actualizará al obtener la ubicación.
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(19.4326, -99.1332), // Centro de la Ciudad de México
    zoom: 14.0,
  );

  /// Obtiene la posición inicial del usuario al arrancar la app.
  /// Usa tu paquete 'geolocator' que ya tenías.
  Future<Position?> getCurrentUserPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Puedes pedirle al usuario que active los servicios de ubicación.
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print("Error getting initial position: $e");
      return null;
    }
  }

  /// Mueve la cámara del mapa suavemente a una nueva posición.
  Future<void> animateCameraToPosition(LatLng position) async {
    final GoogleMapController controller = await mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: 16.5, tilt: 30.0),
    ));
  }

  /// Actualiza la posición del marcador del conductor en el mapa.
  /// Este método reemplaza al antiguo 'addUserMarker'.
  void updateUserMarker(LatLng position) {
    // Usamos un ID constante para el marcador del conductor.
    const markerId = MarkerId('currentUser');

    final newMarker = Marker(
      markerId: markerId,
      position: position,
      // (Opcional) Puedes añadir un ícono personalizado aquí si quieres
      // icon: BitmapDescriptor.fromAsset('assets/images/car_icon.png'),
    );

    // Esta lógica es clave:
    // 1. Busca si ya existe un marcador con ese ID y lo elimina.
    // 2. Añade el nuevo marcador con la posición actualizada.
    // El efecto visual es que el marcador "se mueve".
    markers.removeWhere((m) => m.markerId == markerId);
    markers.add(newMarker);
  }

  /// Libera los recursos del controlador del mapa cuando la pantalla se destruye.
  void dispose() {
    // No es necesario llamar a dispose() en el completer,
    // el controlador se libera automáticamente.
  }
}
