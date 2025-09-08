// ServiceWorkScreen.dart - Pantalla de trabajo del técnico
import 'dart:async';
import 'dart:io';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/services/TechnicianService.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
 import 'package:url_launcher/url_launcher.dart';

class ServiceWorkScreen extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  final VoidCallback? onServiceComplete;

  const ServiceWorkScreen({
    Key? key,
    required this.serviceRequest,
    this.onServiceComplete,
  }) : super(key: key);

  @override
  State<ServiceWorkScreen> createState() => _ServiceWorkScreenState();
}

class _ServiceWorkScreenState extends State<ServiceWorkScreen> {
  final ImagePicker _picker = ImagePicker();

  // Fotos del servicio
  File? _beforePhoto;
  File? _afterPhoto;
  File? _vehiclePhoto;
  bool _vehiclePhotoUploaded = false;
  bool _beforePhotoUploaded = false;
  bool _afterPhotoUploaded = false;

  // Estados
  bool _isLoading = false;
  bool _serviceStarted = false;
  DateTime? _serviceStartTime;

  // Controladores de texto
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _batteryLevelController = TextEditingController();
  final TextEditingController _chargeTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize listeners
    _batteryLevelController.addListener(_onTextFieldChanged);
    _chargeTimeController.addListener(_onTextFieldChanged);
    _notesController.addListener(_onTextFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move context-dependent operations here
    _markServiceAsOnSite();
    _loadServiceProgress();
    _startService();
  }

  Future<void> _markServiceAsOnSite() async {
    try {
      final localizations = AppLocalizations.of(context);
      await TechnicianService.updateServiceStatus(
        widget.serviceRequest.id,
        'on_site',
        notes: localizations.technicianArrivedMessage,
      );
    } catch (e) {
      print('Error updating service status: $e');
      _showErrorSnackbar(AppLocalizations.of(context).errorChangingStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(localizations),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildClientInfoCard(localizations),
                  const SizedBox(height: 16),
                  _buildServiceProgressCard(localizations),
                  const SizedBox(height: 16),
                  _buildPhotoSection(localizations),
                  const SizedBox(height: 16),
                  _buildServiceDetailsSection(localizations),
                  const SizedBox(height: 24),
                  _buildCompleteServiceButton(localizations),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations localizations) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          localizations.technicianOnSite,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.brandBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.electric_bolt,
              color: Colors.white.withOpacity(0.3),
              size: 80,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfoCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                widget.serviceRequest.user?.name.isNotEmpty == true
                    ? widget.serviceRequest.user!.name[0].toUpperCase()
                    : 'C',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceRequest.user?.name ?? localizations.client,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.chargeServiceRequested,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      localizations.onSite,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _callClient,
              icon: Icon(Icons.phone, color: AppColors.success),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.success.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceProgressCard(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  localizations.serviceProgress,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_serviceStarted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startService,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(localizations.serviceInitiatedTitle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${localizations.serviceInitiatedTitle}: ${_formatTime(_serviceStartTime!)}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceTimer(localizations),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTimer(AppLocalizations localizations) {
    if (_serviceStartTime == null) return const SizedBox();

    return StreamBuilder<DateTime>(
      stream:
          Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final elapsed = now.difference(_serviceStartTime!);
        final minutes = elapsed.inMinutes;
        final seconds = elapsed.inSeconds % 60;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Text(
                '${localizations.timeElapsed}: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoSection(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  localizations.technicianWillDocumentProgress,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Foto del vehículo
            _buildPhotoCard(
              title: localizations.serviceVehicle,
              subtitle: localizations.vehicleNeeded,
              photo: _vehiclePhoto,
              onTap: () => _takePhoto('vehicle'),
              icon: Icons.directions_car,
              color: AppColors.info,
              uploaded: _vehiclePhotoUploaded,
            ),

            const SizedBox(height: 12),

            // Foto antes de la carga
            _buildPhotoCard(
              title: localizations.initial,
              subtitle: localizations.batteryLevel,
              photo: _beforePhoto,
              onTap: () => _takePhoto('before'),
              icon: Icons.battery_0_bar,
              color: AppColors.warning,
              uploaded: _beforePhotoUploaded,
            ),

            const SizedBox(height: 12),

            // Foto después de la carga
            _buildPhotoCard(
              title: localizations.serviceCompletedTitle,
              subtitle: localizations.batteryLevel,
              photo: _afterPhoto,
              onTap: () => _takePhoto('after'),
              icon: Icons.battery_full,
              color: AppColors.success,
              enabled: _serviceStarted,
              uploaded: _afterPhotoUploaded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String subtitle,
    required File? photo,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    bool enabled = true,
    bool uploaded = false,
  }) {
    final localizations = AppLocalizations.of(context);
    final bool isComplete = photo != null || uploaded;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                enabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: isComplete
              ? Colors.green.withOpacity(0.05)
              : (enabled ? Colors.transparent : Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (enabled ? color : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isComplete ? Icons.check_circle : icon,
                color:
                    isComplete ? Colors.green : (enabled ? color : Colors.grey),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.textPrimary : Colors.grey,
                    ),
                  ),
                  Text(
                    uploaded && photo == null
                        ? localizations.vehicleRegisteredSuccess
                        : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: uploaded && photo == null
                          ? Colors.green
                          : (enabled ? AppColors.textSecondary : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            if (photo != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(photo),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (uploaded)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.green.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.cloud_done,
                  color: Colors.green,
                  size: 20,
                ),
              )
            else
              Icon(
                Icons.camera_alt,
                color: enabled ? color : Colors.grey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsSection(AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  localizations.serviceInformation,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nivel de batería inicial
            TextField(
              controller: _batteryLevelController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                labelText: localizations.batteryLevel,
                hintText: 'Ej: 15',
                prefixIcon: Icon(Icons.battery_std, color: AppColors.warning),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tiempo de carga
            TextField(
              controller: _chargeTimeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: localizations.chargingTime,
                hintText: 'Ej: 45',
                prefixIcon: Icon(Icons.timer, color: AppColors.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notas adicionales
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: localizations.addComment,
                hintText: localizations.describeService,
                prefixIcon:
                    Icon(Icons.note_add, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteServiceButton(AppLocalizations localizations) {
    final bool hasVehiclePhoto = _vehiclePhoto != null || _vehiclePhotoUploaded;
    final bool hasBeforePhoto = _beforePhoto != null || _beforePhotoUploaded;
    final bool hasAfterPhoto = _afterPhoto != null || _afterPhotoUploaded;

    final bool canComplete =
        hasVehiclePhoto && hasBeforePhoto && hasAfterPhoto && _serviceStarted;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canComplete && !_isLoading ? _completeService : null,
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _isLoading ? localizations.processing : localizations.finishService,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canComplete ? AppColors.success : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canComplete ? 3 : 0,
        ),
      ),
    );
  }

  Future<void> _loadServiceProgress() async {
    try {
      final progressData =
          await TechnicianService.getServiceProgress(widget.serviceRequest.id);

      if (progressData != null && progressData['has_progress'] == true) {
        final progress = progressData['progress'];

        setState(() {
          _serviceStarted = progress['service_started'] ?? false;

          if (progress['service_start_time'] != null) {
            _serviceStartTime = DateTime.parse(progress['service_start_time']);
          }

          _batteryLevelController.text =
              progress['initial_battery_level'] != null
                  ? progress['initial_battery_level'].toString()
                  : '';
          _chargeTimeController.text = progress['charge_time_minutes'] != null
              ? progress['charge_time_minutes'].toString()
              : '';
          _notesController.text = progress['service_notes']?.toString() ?? '';

          _vehiclePhotoUploaded = progress['vehicle_photo_url'] != null &&
              progress['vehicle_photo_url'].toString().isNotEmpty;
          _beforePhotoUploaded = progress['before_photo_url'] != null &&
              progress['before_photo_url'].toString().isNotEmpty;
          _afterPhotoUploaded = progress['after_photo_url'] != null &&
              progress['after_photo_url'].toString().isNotEmpty;

          print('Estado de fotos cargado:');
          print('- Vehicle uploaded: $_vehiclePhotoUploaded');
          print('- Before uploaded: $_beforePhotoUploaded');
          print('- After uploaded: $_afterPhotoUploaded');
        });

        print('Progreso del servicio restaurado');
      }
    } catch (e) {
      print('Error cargando progreso: $e');
      _showErrorSnackbar(AppLocalizations.of(context).errorLoadingData);
    }
  }

  Future<void> _saveProgress() async {
    final photosTaken = <String>[];
    if (_vehiclePhoto != null) photosTaken.add('vehicle');
    if (_beforePhoto != null) photosTaken.add('before');
    if (_afterPhoto != null) photosTaken.add('after');

    await TechnicianService.saveServiceProgress(
      serviceId: widget.serviceRequest.id,
      serviceStarted: _serviceStarted,
      serviceStartTime: _serviceStartTime,
      initialBatteryLevel: _batteryLevelController.text.isNotEmpty
          ? _batteryLevelController.text
          : null,
      chargeTimeMinutes: _chargeTimeController.text.isNotEmpty
          ? _chargeTimeController.text
          : null,
      serviceNotes:
          _notesController.text.isNotEmpty ? _notesController.text : null,
      photosTaken: photosTaken,
    );
  }

  void _onTextFieldChanged() {
    Timer(const Duration(milliseconds: 1000), () {
      _saveProgress();
    });
  }

  Future<void> _startService() async {
    try {
      final localizations = AppLocalizations.of(context);
      await TechnicianService.updateServiceStatus(
        widget.serviceRequest.id,
        'charging',
        notes: localizations.serviceInitiatedMessage,
      );

      setState(() {
        _serviceStarted = true;
        _serviceStartTime = DateTime.now();
      });

      await _saveProgress();

      HapticFeedback.lightImpact();
      _showSuccessSnackbar(localizations.serviceInitiatedMessage);
    } catch (e) {
      _showErrorSnackbar(
          '${AppLocalizations.of(context).errorChangingStatus}: $e');
    }
  }

  Future<void> _takePhoto(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          switch (type) {
            case 'vehicle':
              _vehiclePhoto = File(image.path);
              break;
            case 'before':
              _beforePhoto = File(image.path);
              break;
            case 'after':
              _afterPhoto = File(image.path);
              break;
          }
        });

        try {
          final success = await TechnicianService.uploadServicePhotos(
            serviceId: widget.serviceRequest.id,
            photos: [File(image.path)],
            photoTypes: [type],
          );

          if (success) {
            print('✅ Foto $type subida exitosamente');
          } else {
            print('❌ Error subiendo foto $type');
            _showErrorSnackbar(AppLocalizations.of(context).errorLoadingData);
          }
        } catch (e) {
          print('❌ Error en upload de foto: $e');
          _showErrorSnackbar(
              '${AppLocalizations.of(context).errorLoadingData}: $e');
        }

        await _saveProgress();

        HapticFeedback.lightImpact();
        _showSuccessSnackbar(AppLocalizations.of(context).vehicleRegisteredSuccess);
      }
    } catch (e) {
      _showErrorSnackbar('${AppLocalizations.of(context).errorLoadingData}: $e');
    }
  }

  Future<void> _completeService() async {
    setState(() => _isLoading = true);

    try {
      final localizations = AppLocalizations.of(context);
      final photos = <File>[];
      final photoTypes = <String>[];

      if (_vehiclePhoto != null) {
        photos.add(_vehiclePhoto!);
        photoTypes.add('vehicle');
      }
      if (_beforePhoto != null) {
        photos.add(_beforePhoto!);
        photoTypes.add('before');
      }
      if (_afterPhoto != null) {
        photos.add(_afterPhoto!);
        photoTypes.add('after');
      }

      await TechnicianService.saveServiceDetails(
        serviceId: widget.serviceRequest.id,
        initialBatteryLevel: int.tryParse(_batteryLevelController.text),
        chargeTimeMinutes: int.tryParse(_chargeTimeController.text),
        serviceNotes:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        photos: photos.isNotEmpty ? photos : null,
        photoTypes: photoTypes.isNotEmpty ? photoTypes : null,
      );

      await TechnicianService.updateServiceStatus(
        widget.serviceRequest.id,
        'completed',
        notes: _buildServiceNotes(localizations),
      );

      HapticFeedback.heavyImpact();

      _showCompletionDialog(localizations);
    } catch (e) {
      _showErrorSnackbar(
          '${AppLocalizations.of(context).serviceCompleted}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _buildServiceNotes(AppLocalizations localizations) {
    final buffer = StringBuffer();
    buffer.writeln(localizations.serviceCompletedSuccessfully);

    if (_batteryLevelController.text.isNotEmpty) {
      buffer.writeln(
          '${localizations.batteryLevel}: ${_batteryLevelController.text}%');
    }

    if (_chargeTimeController.text.isNotEmpty) {
      buffer.writeln(
          '${localizations.chargingTime}: ${_chargeTimeController.text} ${localizations.min}');
    }

    if (_notesController.text.isNotEmpty) {
      buffer.writeln('${localizations.addComment}: ${_notesController.text}');
    }

    buffer.writeln(
        '${localizations.technicianWillDocumentProgress}: ${_vehiclePhoto != null ? '✓' : '✗'} ${localizations.serviceVehicle}, ${_beforePhoto != null ? '✓' : '✗'} ${localizations.initial}, ${_afterPhoto != null ? '✓' : '✗'} ${localizations.serviceCompletedTitle}');

    return buffer.toString();
  }

  void _showCompletionDialog(AppLocalizations localizations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(localizations.serviceCompletedTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.serviceCompletedMessage,
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizations.thankYouForYourRating,
                style: GoogleFonts.inter(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => BottomNavBar(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              localizations.continueText,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callClient() async {
    final localizations = AppLocalizations.of(context);
    final clientPhone = widget.serviceRequest.user?.phone;
    if (clientPhone != null && clientPhone.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: clientPhone);
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          _showErrorSnackbar(localizations.couldNotOpenPhoneApp);
        }
      } catch (e) {
        _showErrorSnackbar('${localizations.errorMakingCall}: $e');
      }
    } else {
      _showErrorSnackbar(localizations.noPhoneNumberAvailable);
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _saveProgress();
    _batteryLevelController.removeListener(_onTextFieldChanged);
    _chargeTimeController.removeListener(_onTextFieldChanged);
    _notesController.removeListener(_onTextFieldChanged);

    _notesController.dispose();
    _batteryLevelController.dispose();
    _chargeTimeController.dispose();
    super.dispose();
  }
}