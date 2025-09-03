// utils/AuthWrapper.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'dart:developer' as developer; // Usaremos el log potente

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    developer.log(
        '--- AuthWrapper: initState() ---'); // Pista 1: ¿Se crea el widget?
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _checkSessionAndRedirect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndRedirect() async {
    // ▼▼▼ EL "ATRAPA-ERRORES" GIGANTE ▼▼▼
    try {
      developer.log(
          '--- AuthWrapper: Inicia _checkSessionAndRedirect ---'); // Pista 2
      _animationController.repeat();

      developer.log(
          '--- AuthWrapper: Llamando a AuthService.fetchUserProfile... ---'); // Pista 3
      final user = await AuthService.fetchUserProfile();
      developer.log(
          '--- AuthWrapper: Resultado de fetchUserProfile: ${user?.name ?? 'null'} ---'); // Pista 4

      if (!mounted) return;

      _animationController.stop();

      if (user != null) {
        developer.log(
            '--- AuthWrapper: Usuario VÁLIDO. Navegando a /home... ---'); // Pista 5a
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        developer
            .log('--- AuthWrapper: Usuario INVÁLIDO o nulo. ---'); // Pista 5b
        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding =
            prefs.getBool('onboarding_completed') ?? false;

        if (hasSeenOnboarding) {
          developer
              .log('--- AuthWrapper: Navegando a /login... ---'); // Pista 6a
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          developer.log(
              '--- AuthWrapper: Navegando a /onboarding... ---'); // Pista 6b
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e, stackTrace) {
      // Si cualquier cosa dentro del 'try' falla, se ejecutará esto.
      developer.log('🔥🔥🔥 ERROR CATASTRÓFICO EN AUTHWRAPPER 🔥🔥🔥');
      developer.log('Error: $e');
      developer.log('Stack Trace: $stackTrace');

      // Por seguridad, si hay un error, lo mandamos al login.
      if (mounted) {
        _animationController.stop();
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedTruckProgress(
          animation: _animationController,
        ),
      ),
    );
  }
}
