import 'package:Voltgo_app/data/models/User/UserModel.dart';
import 'package:Voltgo_app/data/services/auth_api_service.dart';
 import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditTechnicianProfileScreen extends StatefulWidget {
  final UserModel? user;

  const EditTechnicianProfileScreen({
    Key? key,
    this.user,
  }) : super(key: key);

  @override
  State<EditTechnicianProfileScreen> createState() => _EditTechnicianProfileScreenState();
}

class _EditTechnicianProfileScreenState extends State<EditTechnicianProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _baseLocationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  
  List<String> _servicesOffered = [];
  File? _idDocument;
  bool _isLoading = false;
  bool _hasChanges = false;
  UserModel? _currentUser;

  // Servicios disponibles para técnicos
  final List<String> _availableServices = [
    'Carga rápida DC',
    'Carga lenta AC',
    'Carga de emergencia',
    'Mantenimiento básico',
    'Diagnóstico de batería',
    'Reparación menor',
    'Asistencia en carretera',
    'Instalación de cargadores',
    'Consultoría técnica',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() async {
  if (widget.user != null) {
    _currentUser = widget.user;
   } else {
    await _loadUserProfile();
  }
}
 

// Método auxiliar para cargar el perfil desde el servidor
Future<void> _loadUserProfile() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final userProfile = await AuthService.fetchUserProfile();
    if (userProfile != null && mounted) {
      setState(() {
        _currentUser = userProfile;
      });
     } else {
      if (mounted) {
        _showErrorDialog('No se pudo cargar el perfil del usuario');
      }
    }
  } catch (e) {
    if (mounted) {
      _showErrorDialog('Error al cargar perfil: $e');
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _baseLocationController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Mostrar opciones para seleccionar cámara o galería
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seleccionar documento',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      
      if (source != null) {
        final XFile? file = await picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        
        if (file != null) {
          setState(() {
            _idDocument = File(file.path);
            _hasChanges = true;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Error al seleccionar documento: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_servicesOffered.isEmpty) {
      _showErrorDialog('Debes seleccionar al menos un servicio');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.updateTechnicianProfile(
        phone: _phoneController.text.trim(),
        baseLocation: _baseLocationController.text.trim(),
        servicesOffered: _servicesOffered,
        licenseNumber: _licenseNumberController.text.trim().isEmpty 
            ? null 
            : _licenseNumberController.text.trim(),
        idDocument: _idDocument,
      );
      
      if (mounted) {
        if (result.success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(result.error ?? 'Error desconocido');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profileUpdated ?? 'Perfil actualizado'),
        content: Text(l10n.profileUpdatedSuccessfully ?? 'Tu perfil se ha actualizado correctamente.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Volver con resultado
            },
            child: Text(l10n.accept ?? 'Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.accept ?? 'Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges ?? 'Cambios sin guardar'),
        content: Text(l10n.discardChanges ?? '¿Deseas descartar los cambios realizados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discard ?? 'Descartar'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            l10n.editProfile,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.brandBlue.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4,
          shadowColor: AppColors.gray300.withOpacity(0.4),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: Text(
                  l10n.save ?? 'Guardar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading && _currentUser == null
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTechnicianInfoCard(),
                      const SizedBox(height: 24),
                      _buildContactInfoSection(),
                      const SizedBox(height: 24),
                      _buildProfessionalInfoSection(),
                      const SizedBox(height: 24),
                      _buildServicesSection(),
                      const SizedBox(height: 24),
                      _buildDocumentSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTechnicianInfoCard() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.engineering,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.name ?? l10n.loading ?? 'Cargando...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentUser?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.technician ?? 'Técnico Certificado',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.contactInformation ?? 'Información de contacto',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
                hintText: '+52 123 456 7890',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fieldRequired;
                }
                if (value.trim().length < 10) {
                  return l10n.phoneMinLength ?? 'Teléfono debe tener al menos 10 dígitos';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoSection() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.professionalInformation ?? 'Información profesional',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _baseLocationController,
              decoration: InputDecoration(
                labelText: l10n.baseLocation ?? 'Ubicación base',
                prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
                hintText: 'Ciudad, Estado',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseNumberController,
              decoration: InputDecoration(
                labelText: l10n.licenseNumber ?? 'Número de licencia (opcional)',
                prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
                hintText: 'LIC-123456',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.servicesOffered ?? 'Servicios ofrecidos',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.selectServices ?? 'Selecciona los servicios que ofreces:',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableServices.map((service) {
                final isSelected = _servicesOffered.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _servicesOffered.add(service);
                      } else {
                        _servicesOffered.remove(service);
                      }
                      _hasChanges = true;
                    });
                    HapticFeedback.lightImpact();
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_servicesOffered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.selectAtLeastOneService ?? 'Selecciona al menos un servicio',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection() {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.identificationDocument ?? 'Documento de identificación',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_idDocument != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.documentSelected ?? 'Documento seleccionado',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _idDocument!.path.split('/').last,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _idDocument = null;
                          _hasChanges = true;
                        });
                      },
                      child: Text(
                        l10n.remove ?? 'Quitar',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.upload_file),
              label: Text(_idDocument == null 
                  ? (l10n.uploadDocument ?? 'Subir documento') 
                  : (l10n.changeDocument ?? 'Cambiar documento')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.documentInfo ?? 'Formatos soportados: JPG, PNG (máx. 5MB)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _hasChanges ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasChanges ? AppColors.primary : AppColors.gray300,
          foregroundColor: _hasChanges ? Colors.white : AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _hasChanges ? 4 : 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasChanges ? Icons.save : Icons.check,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasChanges 
                        ? (l10n.saveChanges ?? 'Guardar cambios')
                        : (l10n.noChanges ?? 'Sin cambios'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}