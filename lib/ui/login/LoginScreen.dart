import 'dart:convert';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/ui/MenuPage/DashboardScreen.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/login/ForgotPasswordScreen.dart';
import 'package:Voltgo_app/ui/login/RegisterScreen.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_app/utils/encryption_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;
  final _emailController =
      TextEditingController(); // Antes se llamaba _usernameController

  final _passwordController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState); // Usa el nuevo nombre

    _passwordController.addListener(_updateButtonState);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    if (!_isButtonEnabled || _isLoading) return;

    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      // ▼▼▼ CAMBIO 1: El tipo de la variable ahora es LoginResult ▼▼▼
      final loginResult = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _animationController.stop();
      if (!mounted) return;

      // ▼▼▼ CAMBIO 2: La condición ahora es más simple y directa ▼▼▼
      if (loginResult.success) {
        // Si fue exitoso, el token YA ESTÁ GUARDADO. Solo navega.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const BottomNavBar()), // O tu ruta '/home'
          (Route<dynamic> route) => false,
        );
      } else {
        // Si no fue exitoso, muestra el error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                loginResult.error ?? l10n.incorrectUserPassword), // ✅ CAMBIAR
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.serverConnectionError), // ✅ CAMBIAR
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    // ▼▼▼ MODIFICADO: Espaciado ajustado ▼▼▼
                    const SizedBox(height: 24),
                    // ▼▼▼ NUEVO: Widget para los botones de login social ▼▼▼
                    _buildSocialLogins(),
                    // ▼▼▼ MODIFICADO: Espaciado ajustado ▼▼▼
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: AnimatedTruckProgress(
                animation: _animationController,
              ),
            ),
        ],
      ),
    );
  }

  // ▼▼▼ NUEVO: Widget para mostrar botones de Google y Apple ▼▼▼
  Widget _buildSocialLogins() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                l10n.or,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        // Botón de Google
        _buildSocialButton(
          assetName: 'assets/images/gugel.png',
          text:
              l10n.signInWithGoogle, // ✅ CAMBIAR de 'Iniciar sesión con Google'
          onPressed: () {
            print('Login con Google presionado');
          },
        ),
        const SizedBox(height: 12),
        // Botón de Apple
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          // MODIFICADO: Texto del botón
          text: l10n.signInWithApple, // ✅ CAMBIAR de 'Iniciar sesión con Apple'
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implementar la lógica de inicio de sesión con Apple
            print('Login con Apple presionado');
          },
        ),
      ],
    );
  }

  // ▼▼▼ NUEVO: Helper para crear botones de login social genéricos ▼▼▼
  Widget _buildSocialButton({
    required String assetName,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Image.asset(assetName, height: 22, width: 22),
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.white,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: BorderSide(color: AppColors.gray300),
        ),
      ),
    );
  }

  // --- Widgets existentes (con pequeñas modificaciones) ---

  Widget _buildBackground(BuildContext context) {
    return Stack(children: [
      Positioned(
        bottom: 0,
        left: 0,
        child: Image.asset(
          'assets/images/rectangle3.png',
          width: MediaQuery.of(context).size.width * 0.5,
          fit: BoxFit.contain,
          color: AppColors.primary, // Color que quieras aplicar
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Center(
      child: Column(
        children: [
          // Contenedor con fondo redondeado para la imagen
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary, // Color de fondo
              borderRadius: BorderRadius.circular(20), // Esquinas redondeadas
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16), // Espacio interno
            child: Image.asset(
              'assets/images/logoAppVoltgo.png',
              height: 120,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.welcomeTechnician, // ✅ CAMBIAR de 'Bienvenido Tecnico.'

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: l10n.email, // ✅ YA EXISTE
          hint: l10n.enterEmail, // ✅ YA EXISTE
          controller: _emailController,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(controller: _passwordController),
        const SizedBox(height: 20),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled && !_isLoading ? _login : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled && !_isLoading
                    ? AppColors.brandBlue
                    : AppColors.gray300,
                disabledBackgroundColor: AppColors.gray300,
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                elevation: 0),
            child: Text(l10n.signIn, // ✅ YA EXISTE de 'Iniciar sesión'

                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
          ),
        )
      ],
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.noAccount, // ✅ YA EXISTE de '¿No tienes una cuenta? '

                style: TextStyle(
                    fontSize: 15,
                    color: AppColors.black,
                    fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: Text(l10n.createHere, // ✅ YA EXISTE de 'Créala aquí.'

                  style: TextStyle(
                      color: AppColors.brandBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        /*
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavBar()),
            );
          },
          child: const Text('Recupera tu cuenta.',
              style: TextStyle(
                  color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
        ),
        */
      ],
    );
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(
                      color: AppColors.brandBlue, width: 1.5))))
    ]);
  }

  Widget _buildPasswordField({required TextEditingController controller}) {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.password, // ✅ YA EXISTE de 'Contraseña'

          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
              hintText:
                  l10n.enterPassword, // ✅ YA EXISTE de 'Ingresa tu contraseña'
              filled: true,
              fillColor: AppColors.lightGrey.withOpacity(0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.gray300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide:
                      const BorderSide(color: AppColors.brandBlue, width: 1.5)),
              suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  })))
    ]);
  }
}
