import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/map_picker_screen.dart';
import 'package:Voltgo_app/utils/AnimatedTruckProgress.dart';
import 'package:Voltgo_app/utils/bottom_nav.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
import 'dart:developer' as developer;

class GoogleProfileCompletionScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const GoogleProfileCompletionScreen({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  _GoogleProfileCompletionScreenState createState() =>
      _GoogleProfileCompletionScreenState();
}

class _GoogleProfileCompletionScreenState
    extends State<GoogleProfileCompletionScreen>
    with SingleTickerProviderStateMixin {
  
  // Controllers
  final _phoneController = TextEditingController();
  final _baseLocationController = TextEditingController();
  final _otherServiceController = TextEditingController();
  final _licenseController = TextEditingController();

  // State variables
  String? _fullPhoneNumber;
  final Set<String> _selectedServices = {};
  bool _showOtherServiceField = false;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  File? _pickedIdFile;
  bool _isPickingFile = false;

  List<String> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_updateButtonState);
    _baseLocationController.addListener(_updateButtonState);
    _otherServiceController.addListener(_updateButtonState);
    _licenseController.addListener(_updateButtonState);

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _phoneController.dispose();
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
      _isButtonEnabled = _fullPhoneNumber != null &&
          _fullPhoneNumber!.isNotEmpty &&
          _baseLocationController.text.trim().isNotEmpty &&
          _selectedServices.isNotEmpty &&
          otherServiceValid;
    });
  }

  Future<void> _completeProfile() async {
    if (!_isButtonEnabled || _isLoading) return;


// ✅ AGREGAR ESTE DEBUG
  developer.log('=== PROFILE COMPLETION DEBUG ===');
  developer.log('_fullPhoneNumber: "$_fullPhoneNumber"');
  developer.log('_baseLocationController.text: "${_baseLocationController.text}"');
  developer.log('_baseLocationController.text.trim(): "${_baseLocationController.text.trim()}"');
  developer.log('_selectedServices: $_selectedServices');
 
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
      // Aquí necesitas crear un método en AuthService para actualizar el perfil
      final response = await AuthService.updateTechnicianProfile(
        phone: _fullPhoneNumber!,
        baseLocation: _baseLocationController.text.trim(),
        servicesOffered: servicesToSend,
        licenseNumber: _licenseController.text.trim().isEmpty 
            ? null 
            : _licenseController.text.trim(),
        idDocument: _pickedIdFile,
      );

      _animationController.stop();
      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text( 'Profile add.'),
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
          SnackBar(
            content: Text(response.error ?? 'Error completando el perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickIdFile() async {
    setState(() => _isPickingFile = true);
    final localizations = AppLocalizations.of(context);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionando archivo: $e')),
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
        _updateButtonState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Complete Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con información del usuario
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 48,
                          color: AppColors.brandBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hi, ${widget.userName}!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete your technician profile to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Campos obligatorios
                  Text(
                    'Required Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildPhoneField(),
                  const SizedBox(height: 20),
                  
                  _buildLocationPicker(),
                  const SizedBox(height: 20),
                  
                  _buildServicesSelection(),
                  
                  if (_showOtherServiceField) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: localizations.otherService,
                      hint: localizations.describeService,
                      controller: _otherServiceController,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Información opcional
                  Text(
                    'Optional Information',
                    style: TextStyle(
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
                  const SizedBox(height: 40),
                  
                  // Botón de completar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled && !_isLoading ? _completeProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled && !_isLoading
                            ? AppColors.brandBlue
                            : AppColors.gray300,
                        disabledBackgroundColor: AppColors.gray300,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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

  // Métodos helper (copiados del RegisterScreen)
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
              borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
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
                  color: isSelected ? AppColors.brandBlue : AppColors.textSecondary,
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
              borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
          ),
        )
      ],
    );
  }
}