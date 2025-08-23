import 'dart:io';

import 'package:Voltgo_app/utils/map_picker_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/ui/login/LoginScreen.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_app/utils/TokenStorage.dart';
import 'package:Voltgo_app/utils/bottom_nav.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // --- Controladores para todos los campos ---
  final _nameController = TextEditingController();
  final _phoneController =
      TextEditingController(); // Controlador para el número

  final _emailController = TextEditingController();
  //final _phoneController = TextEditingController(); // Para el número sin LADA
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _baseLocationController = TextEditingController();

  // --- Variables de estado ---
  String? _fullPhoneNumber; // Para guardar LADA + NÚMERO
  final Set<String> _selectedServices = {};

  final List<String> _availableServices = [
    // <-- MODIFICADO
    'Jump Start',
    'EV Charging',
    'Tire Change',
    'Lockout',
    'Fuel Delivery',
    'Otro' // <-- NUEVO
  ];

  bool _showOtherServiceField = false; // <-- NUEVO

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  final _otherServiceController = TextEditingController(); // <-- NUEVO
  final _licenseController = TextEditingController(); // <-- NUEVO

  File? _pickedIdFile; // <-- NUEVO: Para guardar el archivo seleccionado
  bool _isPickingFile = false; // <-- NUEVO: Para estado de carga del picker

  // En _RegisterScreenState
  @override
  void initState() {
    super.initState();
    // Añadimos listeners a todos los controladores para actualizar el estado del botón
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _baseLocationController.addListener(_updateButtonState);
    _otherServiceController.addListener(_updateButtonState); // <-- NUEVO
    _licenseController.addListener(_updateButtonState); // <-- NUEVO

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _baseLocationController.dispose();
    _otherServiceController.dispose(); // <-- NUEVO
    _licenseController.dispose(); // <-- NUEVO

    _animationController.dispose();
    super.dispose();
  }

  // En _RegisterScreenState
  void _updateButtonState() {
    // Verificamos si "Otro" está seleccionado y si el campo de texto está lleno
    final otherServiceValid = !_selectedServices.contains('Otro') ||
        (_selectedServices.contains('Otro') &&
            _otherServiceController.text.trim().isNotEmpty);

    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _fullPhoneNumber != null &&
          _fullPhoneNumber!.isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          _baseLocationController.text
              .trim()
              .isNotEmpty && // Ahora se llena desde el mapa
          _selectedServices.isNotEmpty &&
          otherServiceValid && // <-- NUEVA CONDICIÓN
          (_passwordController.text.trim() ==
              _confirmPasswordController.text.trim());
    });
  }

  Future<void> _register() async {
    if (!_isButtonEnabled || _isLoading) return;

    // Inicia el estado de carga y la animación
    setState(() => _isLoading = true);
    _animationController.repeat();

    // Preparamos la lista de servicios, incluyendo el servicio "Otro" si existe
    final List<String> servicesToSend = _selectedServices
        .where((service) => service != 'Otro') // Quitamos "Otro" de la lista
        .toList();

    if (_selectedServices.contains('Otro') &&
        _otherServiceController.text.trim().isNotEmpty) {
      servicesToSend.add(_otherServiceController.text
          .trim()); // Añadimos el servicio personalizado
    }

    try {
      final response = await AuthService.registerTechnician(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _fullPhoneNumber!,
        baseLocation: _baseLocationController.text.trim(),
        servicesOffered: servicesToSend, // <-- USAMOS LA NUEVA LISTA
        licenseNumber: _licenseController.text.trim(), // <-- NUEVO
        idDocument: _pickedIdFile,
      );

      _animationController.stop();
      if (!mounted) return;

      if (response.success && response.token != null) {
        await TokenStorage.saveToken(response.token!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
          (route) => false,
        );
      } else {
        // ▼▼▼ CORRECCIÓN AQUÍ ▼▼▼
        // Mostramos un mensaje genérico porque 'response' no tiene un campo 'message'.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se pudo completar el registro. Verifica tus datos e inténtalo de nuevo.')),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } catch (e) {
      // ... tu manejo de errores
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickIdFile() async {
    setState(() => _isPickingFile = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _pickedIdFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      // Manejar error si es necesario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar el archivo: $e')),
      );
    } finally {
      setState(() => _isPickingFile = false);
    }
  }

  Future<void> _openMapPicker() async {
    final selectedAddress = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
    );

    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      setState(() {
        _baseLocationController.text = selectedAddress;
        _updateButtonState(); // Actualizamos el botón
      });
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
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildForm(), // El formulario ahora contiene todos los campos
                    const SizedBox(height: 24),
                    _buildSocialLogins(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          // Muestra la animación de carga sobre toda la pantalla
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

  // --- WIDGETS DE CONSTRUCCIÓN DE UI (ESTILO DEL CÓDIGO 2) ---

  Widget _buildHeader() {
    return const Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Crea tu cuenta de Técnico',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text('Completa el formulario para empezar.',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
            label: 'Nombre completo',
            hint: 'Tu nombre y apellido',
            controller: _nameController),
        const SizedBox(height: 20),
        _buildTextField(
            label: 'Correo electrónico',
            hint: 'tucorreo@ejemplo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _buildPhoneField(), // Campo de teléfono estilizado
        const SizedBox(height: 20),
        _buildPasswordField(
            label: 'Contraseña',
            controller: _passwordController,
            isPasswordVisible: _isPasswordVisible,
            onToggleVisibility: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible)),
        const SizedBox(height: 20),
        _buildPasswordField(
            label: 'Confirmar contraseña',
            controller: _confirmPasswordController,
            isPasswordVisible: _isConfirmPasswordVisible,
            onToggleVisibility: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
        const SizedBox(height: 20),

        _buildLocationPicker(),
        const SizedBox(height: 20),

        // --- SECCIÓN DE DATOS OPCIONALES ---
        const Text(
          'Documentación (Opcional)',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),

        // ▼▼▼ NUEVO CAMPO: Licencia de conducir ▼▼▼
        _buildTextField(
          label: 'Número de licencia de conducir',
          hint: 'Ingresa tu número de licencia',
          controller: _licenseController,
        ),
        const SizedBox(height: 20),

        // ▼▼▼ NUEVO CAMPO: Subida de documento ▼▼▼
        _buildFileUploadField(),

        const SizedBox(height: 24),

        _buildServicesSelection(), // Selector de servicios
        if (_showOtherServiceField)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildTextField(
              label: 'Otro servicio',
              hint: 'Describe el servicio que ofreces',
              controller: _otherServiceController,
            ),
          ),

        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isButtonEnabled && !_isLoading ? _register : null,
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
            child: const Text('Crear cuenta',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white)),
          ),
        )
      ],
    );
  }

  Widget _buildFileUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto de ID o certificación (AUN NO FUNCIONA, DEJAR ESTE CAMPO VACIO)',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        // Contenedor que parece un campo de texto pero es un botón
        InkWell(
          onTap: _pickIdFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.gray300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _pickedIdFile == null
                        ? 'Seleccionar archivo (JPG, PNG, PDF)'
                        // Mostramos solo el nombre del archivo
                        : _pickedIdFile!.path.split('/').last,
                    style: TextStyle(
                      color: _pickedIdFile == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _isPickingFile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.upload_file, color: AppColors.brandBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ubicación de Base',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        // Usamos un TextFormField de solo lectura para mostrar el resultado
        TextFormField(
          controller: _baseLocationController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Selecciona una ubicación en el mapa',
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: AppColors.gray300)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map, color: AppColors.brandBlue),
              onPressed: _openMapPicker,
            ),
          ),
          onTap: _openMapPicker,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes una cuenta? ',
            style: TextStyle(color: AppColors.textSecondary)),
        GestureDetector(
          onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Text('Inicia sesión.',
              style: TextStyle(
                  color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSocialLogins() {
    // Este widget se mantiene igual que en el código de ejemplo
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'O',
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
        _buildSocialButton(
          assetName: 'assets/images/gugel.png',
          text: 'Registrarse con Google',
          onPressed: () {
            print('Registro con Google presionado');
          },
        ),
        const SizedBox(height: 12),
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          text: 'Registrarse con Apple',
          backgroundColor: Colors.black, // Color estándar para Apple
          textColor: Colors.white,
          onPressed: () {
            print('Registro con Apple presionado');
          },
        ),
      ],
    );
  }

  // --- HELPERS PARA WIDGETS ESPECÍFICOS Y NUEVOS ---

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Teléfono móvil',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Número de teléfono',
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
          ),
          initialCountryCode: 'MX',
          onChanged: (phone) {
            setState(() {
              _fullPhoneNumber = phone.completeNumber;
            });

            _updateButtonState(); // Actualiza el estado del botón cada vez que cambia
          },
        ),
      ],
    );
  }

  Widget _buildServicesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Servicios que ofreces',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _availableServices.map((service) {
            final isSelected = _selectedServices.contains(service);
            return FilterChip(
              label: Text(service,
                  style: TextStyle(
                      color: isSelected
                          ? AppColors.brandBlue
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.remove(service);
                  }

                  if (service == 'Otro') {
                    _showOtherServiceField = selected;
                    if (!selected) {
                      _otherServiceController.clear();
                    }
                  }

                  _updateButtonState(); // Actualiza el botón al cambiar la selección
                });
              },
              backgroundColor: AppColors.lightGrey.withOpacity(0.5),
              selectedColor: AppColors.brandBlue.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(
                      color: isSelected
                          ? AppColors.brandBlue
                          : AppColors.gray300)),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- HELPERS GENÉRICOS (MANTENIDOS DEL CÓDIGO 2) ---

  Widget _buildBackground(BuildContext context) {
    return Stack(children: [
      Positioned(
          top: 0,
          right: -90,
          child: Image.asset('assets/images/rectangle1.png',
              width: MediaQuery.of(context).size.width * 0.5,
              color: AppColors.primary,
              colorBlendMode: BlendMode.srcIn,
              fit: BoxFit.contain)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Image.asset('assets/images/rectangle3.png',
              color: AppColors.primary,
              colorBlendMode: BlendMode.srcIn,
              width: MediaQuery.of(context).size.width * 0.5,
              fit: BoxFit.contain))
    ]);
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller,
      TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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

  Widget _buildPasswordField(
      {required String label,
      required TextEditingController controller,
      required bool isPasswordVisible,
      required VoidCallback onToggleVisibility}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
              hintText: 'Mínimo 8 caracteres',
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
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary),
                  onPressed: onToggleVisibility)))
    ]);
  }

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
}
