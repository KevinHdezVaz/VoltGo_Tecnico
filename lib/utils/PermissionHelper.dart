// lib/utils/PermissionHelper.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHelper {
  /// Solicita permisos para archivos y almacenamiento
  static Future<bool> requestStoragePermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidStoragePermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    }
    return true; // Para otras plataformas
  }

  /// Permisos específicos para Android
  static Future<bool> _requestAndroidStoragePermissions() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;

      List<Permission> permissionsToRequest = [];

      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - Permisos granulares
        permissionsToRequest.addAll([
          Permission.photos, // Para imágenes
          Permission.videos, // Para videos
          Permission.audio,  // Para audio
        ]);
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32)
        permissionsToRequest.addAll([
          Permission.storage,
          Permission.manageExternalStorage,
        ]);
      } else {
        // Android 10 y anteriores (API 29-)
        permissionsToRequest.addAll([
          Permission.storage,
        ]);
      }

      // Solicitar permisos
      Map<Permission, PermissionStatus> statuses =
          await permissionsToRequest.request();

      // Para Android 13+, verificar al menos uno de los permisos granulares
      if (sdkInt >= 33) {
        return statuses[Permission.photos] == PermissionStatus.granted ||
               statuses[Permission.videos] == PermissionStatus.granted ||
               statuses[Permission.audio] == PermissionStatus.granted;
      } else {
        // Para versiones anteriores, verificar si todos fueron concedidos
        return statuses.values.every(
          (status) => status == PermissionStatus.granted
        );
      }
    } catch (e) {
      print('Error solicitando permisos de Android: $e');
      return false;
    }
  }

  /// Permisos específicos para iOS
  static Future<bool> _requestIOSPermissions() async {
    try {
      // En iOS, es mejor no solicitar permisos por adelantado
      // FilePicker los maneja automáticamente
      return true;
    } catch (e) {
      print('Error solicitando permisos de iOS: $e');
      return true;
    }
  }

  /// Verificar si ya tenemos los permisos necesarios
  static Future<bool> hasStoragePermissions() async {
    if (Platform.isAndroid) {
      try {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final int sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ - Verificar permisos granulares
          final photosGranted = await Permission.photos.isGranted;
          final videosGranted = await Permission.videos.isGranted;
          final audioGranted = await Permission.audio.isGranted;
          
          // Al menos uno debe estar concedido
          return photosGranted || videosGranted || audioGranted;
        } else if (sdkInt >= 30) {
          // Android 11-12
          return await Permission.storage.isGranted &&
              await Permission.manageExternalStorage.isGranted;
        } else {
          // Android 10 y anteriores
          return await Permission.storage.isGranted;
        }
      } catch (e) {
        print('Error verificando permisos de Android: $e');
        return false;
      }
    } else if (Platform.isIOS) {
      // En iOS, siempre retornar true ya que FilePicker maneja los permisos
      return true;
    }
    return true;
  }

  /// Abrir configuración de la app si los permisos fueron denegados
  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error abriendo configuración: $e');
    }
  }

  /// Solicitar permiso de cámara
  static Future<bool> requestCameraPermission() async {
    try {
      final PermissionStatus status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error solicitando permiso de cámara: $e');
      return false;
    }
  }

  /// Verificar permiso de cámara
  static Future<bool> hasCameraPermission() async {
    try {
      return await Permission.camera.isGranted;
    } catch (e) {
      print('Error verificando permiso de cámara: $e');
      return false;
    }
  }
}