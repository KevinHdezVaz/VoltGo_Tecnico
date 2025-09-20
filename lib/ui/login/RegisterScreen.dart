import 'dart:io';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/login/GoogleProfileCompletionScreen.dart';
import 'package:Voltgo_app/utils/PermissionHelper.dart';
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
  // --- Controllers remain the same ---
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _baseLocationController = TextEditingController();
  final _otherServiceController = TextEditingController();
  final _licenseController = TextEditingController();

  // --- State variables ---
  String? _fullPhoneNumber;
  final Set<String> _selectedServices = {};
  bool _showOtherServiceField = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  File? _pickedIdFile;
  bool _isPickingFile = false;

  // Dynamic services list (will be populated in initState)
  List<String> _availableServices = [];

  @override
  void initState() {
    super.initState();
    // Initialize listeners
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _baseLocationController.addListener(_updateButtonState);
    _otherServiceController.addListener(_updateButtonState);
    _licenseController.addListener(_updateButtonState);

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize services list with localized strings
    final localizations = AppLocalizations.of(context);
    _availableServices = [
      localizations.jumpStart,
      localizations.evCharging,
      localizations.tireChange,
      localizations.lockout,
      localizations.fuelDelivery,
      localizations.other,
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _baseLocationController.dispose();
    _otherServiceController.dispose();
    _licenseController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final localizations = AppLocalizations.of(context);
    final otherServiceValid =
        !_selectedServices.contains(localizations.other) ||
            (_selectedServices.contains(localizations.other) &&
                _otherServiceController.text.trim().isNotEmpty);

    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _fullPhoneNumber != null &&
          _fullPhoneNumber!.isNotEmpty &&
          _passwordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          _baseLocationController.text.trim().isNotEmpty &&
          _selectedServices.isNotEmpty &&
          otherServiceValid &&
          (_passwordController.text.trim() ==
              _confirmPasswordController.text.trim());
    });
  }
// NUEVO: Método para registro con Google
Future<void> _registerWithGoogle() async {
  final localizations = AppLocalizations.of(context);
  
  if (_isLoading) return;

  setState(() => _isLoading = true);
  _animationController.repeat();

  try {
    final loginResult = await AuthService.loginWithGoogle();

    _animationController.stop();
    if (!mounted) return;

    if (loginResult.success) {
      // ✅ CORRECCIÓN: Verificar si el perfil ya está completo
      final user = loginResult.user;
      final needsCompletion = user?['phone'] == null || 
                              user?['base_location'] == null || 
                              user?['services_offered'] == null ||
                              (user?['services_offered'] is List && (user?['services_offered'] as List).isEmpty);
      
      if (needsCompletion) {
        // Navegar a completar perfil (caso normal para registro)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleProfileCompletionScreen(
              userName: user?['name'] ?? 'Usuario',
              userEmail: user?['email'] ?? '',
            ),
          ),
        );
      } else {
        // Si ya tiene perfil completo, ir directamente al dashboard
        // (esto puede pasar si el usuario ya se había registrado antes)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loginResult.error ?? localizations.serverConnectionError,
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      _animationController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  Future<void> _register() async {
    if (!_isButtonEnabled || _isLoading) return;

    final localizations = AppLocalizations.of(context);

    setState(() => _isLoading = true);
    _animationController.repeat();

    final List<String> servicesToSend = _selectedServices
        .where((service) => service != localizations.other)
        .toList();

    if (_selectedServices.contains(localizations.other) &&
        _otherServiceController.text.trim().isNotEmpty) {
      servicesToSend.add(_otherServiceController.text.trim());
    }

    try {
      final response = await AuthService.registerTechnician(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _fullPhoneNumber!,
        baseLocation: _baseLocationController.text.trim(),
        servicesOffered: servicesToSend,
        licenseNumber: _licenseController.text.trim(),
        idDocument: _pickedIdFile,
      );

      _animationController.stop();
      if (!mounted) return;

      if (response.success && response.token != null) {
        await TokenStorage.saveToken(response.token!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.registrationSuccessful),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.registrationError)),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${localizations.error}: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _pickIdFile() async {
  setState(() => _isPickingFile = true);
  final localizations = AppLocalizations.of(context);

  try {
    // Para Android: verificar permisos
    if (Platform.isAndroid) {
      final hasPermission = await PermissionHelper.hasStoragePermissions();
      
      if (!hasPermission) {
        final granted = await PermissionHelper.requestStoragePermissions();
        
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se necesitan permisos para acceder a archivos'),
              action: SnackBarAction(
                label: 'Configuración',
                onPressed: () => PermissionHelper.openSettings(),
              ),
            ),
          );
          return;
        }
      }
    }

    // Para iOS: usar directamente FilePicker sin verificar permisos
    FilePickerResult? result;
    
    if (Platform.isIOS) {
      // En iOS, usar el picker directamente
      result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Usar FileType.any en iOS
        allowMultiple: false,
        withData: false, // No cargar datos en memoria
        withReadStream: false,
      );
    } else {
      // En Android, usar extensiones específicas
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );
    }

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      // Verificar que el archivo tenga un path válido
      if (file.path != null && file.path!.isNotEmpty) {
        // En iOS, verificar que sea un tipo de archivo válido
        if (Platform.isIOS) {
          final fileName = file.name.toLowerCase();
          final validExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
          final hasValidExtension = validExtensions.any((ext) => fileName.endsWith('.$ext'));
          
          if (!hasValidExtension) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Por favor selecciona un archivo JPG, PNG o PDF'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
        
        setState(() {
          _pickedIdFile = File(file.path!);
        });
        
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo seleccionado: ${file.name}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('No se pudo obtener la ruta del archivo');
      }
    }
  } catch (e) {
    print('Error seleccionando archivo: $e');
    
    // No mostrar error si el usuario canceló
    if (e.toString().contains('User canceled') || 
        e.toString().contains('cancelled') ||
        e.toString().contains('canceled')) {
      return;
    }
    
    String errorMessage;
    
    if (Platform.isIOS) {
      errorMessage = 'Error al seleccionar archivo. Asegúrate de seleccionar un archivo JPG, PNG o PDF.';
    } else {
      errorMessage = 'Error al seleccionar archivo: ${e.toString()}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isPickingFile = false);
    }
  }
}
 
   Future<void> _openMapPicker() async {
    final selectedAddress = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
    );

    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      setState(() {
        _baseLocationController.text = selectedAddress;
        _updateButtonState();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;
    final hasSocialButtons = isAndroid || isIOS;

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
                    const SizedBox(height: 40),
                    _buildHeader(),
                     
                    // ✅ Botones sociales (solo aparecen en sus plataformas)
                    _buildSocialLogins(),
                    
                    // ✅ Separador (solo aparece si hay botones sociales)
                    _buildDivider(),
                    
                    // ✅ Formulario de registro por email
                    _buildForm(),
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

  
  Widget _buildHeader() {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            localizations.createTechnicianAccount,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;
    final hasSocialButtons = isAndroid || isIOS;

    // Solo mostrar el separador si hay botones sociales
    if (!hasSocialButtons) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or complete the form',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Expanded(child: Divider(thickness: 1)),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
Widget _buildSocialLogins() {
  final localizations = AppLocalizations.of(context);
  final isAndroid = Platform.isAndroid;
  final isIOS = Platform.isIOS;
  
  // Si no hay botones sociales, no mostrar nada
  if (!isAndroid && !isIOS) {
    return const SizedBox.shrink();
  }

  return Column(
    children: [
      // Mostrar divisores y texto "or" solo si hay botones sociales
      if (isAndroid || isIOS) ...[
      
        const SizedBox(height: 40),
      ],
      
      // Botón de Google - Visible en ambas plataformas
      if (isAndroid || isIOS) ...[
        _buildSocialButton(
          assetName: 'assets/images/gugel.png',
          text: localizations.signUpWithGoogle,
          onPressed: _isLoading ? null : _registerWithGoogle,
        ),
        const SizedBox(height: 12),
      ],
      
      // Botón de Apple - Solo visible en iOS
      if (isIOS) ...[
        _buildSocialButton(
          assetName: 'assets/images/appell.png',
          text: localizations.signUpWithApple,
 backgroundColor: Colors.blueGrey,
           textColor: Colors.white,
           colorIcon: Colors.white,
          onPressed: _isLoading ? null : _registerWithApple,
        ),
        const SizedBox(height: 12),
      ],
    ],
  );
}
  // NUEVO: Método para registro con Apple
Future<void> _registerWithApple() async {
  final localizations = AppLocalizations.of(context);
  
  if (_isLoading) return;

  // Verificar disponibilidad
  final isAvailable = await AuthService.isAppleSignInAvailable();
  if (!isAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apple Sign In no está disponible en este dispositivo'),
        backgroundColor: Colors.red.shade600,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);
  _animationController.repeat();

  try {
    final loginResult = await AuthService.loginWithApple();

    _animationController.stop();
    if (!mounted) return;

    if (loginResult.success) {
      final user = loginResult.user;
      final needsCompletion = user?['phone'] == null || 
                              user?['base_location'] == null || 
                              user?['services_offered'] == null ||
                              (user?['services_offered'] is List && (user?['services_offered'] as List).isEmpty);
      
      if (needsCompletion) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GoogleProfileCompletionScreen(
              userName: user?['name'] ?? 'Usuario',
              userEmail: user?['email'] ?? '',
            ),
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (loginResult.error != 'El usuario canceló el inicio de sesión') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loginResult.error ?? localizations.serverConnectionError,
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      _animationController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


  Widget _buildForm() {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: localizations.fullName,
          hint: localizations.yourNameAndSurname,
          controller: _nameController,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          label: localizations.emailAddress,
          hint: localizations.emailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildPhoneField(),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: localizations.password,
          controller: _passwordController,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: localizations.confirmPassword,
          controller: _confirmPasswordController,
          isPasswordVisible: _isConfirmPasswordVisible,
          onToggleVisibility: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        const SizedBox(height: 20),
        _buildLocationPicker(),
        const SizedBox(height: 20),

        // Optional Documentation Section
        Text(
          localizations.optionalDocumentation,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: localizations.driverLicenseNumber,
          hint: localizations.enterLicenseNumber,
          controller: _licenseController,
        ),
        const SizedBox(height: 20),
        _buildFileUploadField(),
        const SizedBox(height: 24),
        _buildServicesSelection(),

        if (_showOtherServiceField)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildTextField(
              label: localizations.otherService,
              hint: localizations.describeService,
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
              elevation: 0,
            ),
            child: Text(
              localizations.createAccount,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildFileUploadField() {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.idPhotoOrCertification,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
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
                        ? localizations.selectFile
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
                    : const Icon(Icons.upload_file, color: AppColors.brandBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.baseLocation,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _baseLocationController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: localizations.selectLocationOnMap,
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
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
    final localizations = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          localizations.alreadyHaveAccount,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: Text(
            localizations.signInHere,
            style: const TextStyle(
              color: AppColors.brandBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.mobilePhone,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: localizations.phoneNumber,
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
          ),
          initialCountryCode: 'MX',
          onChanged: (phone) {
            setState(() {
              _fullPhoneNumber = phone.completeNumber;
            });
            _updateButtonState();
          },
        ),
      ],
    );
  }

  Widget _buildServicesSelection() {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.servicesOffered,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _availableServices.map((service) {
            final isSelected = _selectedServices.contains(service);
            return FilterChip(
              label: Text(
                service,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.brandBlue
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.remove(service);
                  }
                  if (service == localizations.other) {
                    _showOtherServiceField = selected;
                    if (!selected) {
                      _otherServiceController.clear();
                    }
                  }
                  _updateButtonState();
                });
              },
              backgroundColor: AppColors.lightGrey.withOpacity(0.5),
              selectedColor: AppColors.brandBlue.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: isSelected ? AppColors.brandBlue : AppColors.gray300,
                ),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper methods remain largely the same, just with localized hints
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
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
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: localizations.minimumCharacters,
            filled: true,
            fillColor: AppColors.lightGrey.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide:
                  const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSocialButton({
    required String assetName,
    required String text,
    required VoidCallback? onPressed,  
    Color? backgroundColor,
    Color? textColor,
    Color? colorIcon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Image.asset(assetName, height: 22, width: 22, color: colorIcon,),
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

  Widget _buildBackground(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: -90,
          child: Image.asset(
            'assets/images/rectangle1.png',
            width: MediaQuery.of(context).size.width * 0.5,
            color: AppColors.primary,
            colorBlendMode: BlendMode.srcIn,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Image.asset(
            'assets/images/rectangle3.png',
            color: AppColors.primary,
            colorBlendMode: BlendMode.srcIn,
            width: MediaQuery.of(context).size.width * 0.5,
            fit: BoxFit.contain,
          ),
        )
      ],
    );
  }
}