// ServiceWorkScreen.dart - Pantalla de trabajo del técnico
import 'dart:async';
import 'dart:io';
import 'package:Voltgo_app/utils/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/data/services/TechnicianService.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
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
    _markServiceAsOnSite();
    _loadServiceProgress();
    _startService();

    // ✅ CORREGIR: Usar guiones bajos, no asteriscos
    _batteryLevelController.addListener(_onTextFieldChanged);
    _chargeTimeController.addListener(_onTextFieldChanged);
    _notesController.addListener(_onTextFieldChanged);
  }

  Future<void> _markServiceAsOnSite() async {
    try {
      await TechnicianService.updateServiceStatus(
          widget.serviceRequest.id, 'on_site',
          notes: 'Técnico llegó al sitio del cliente');
    } catch (e) {
      print('Error updating service status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildClientInfoCard(),
                  const SizedBox(height: 16),
                  _buildServiceProgressCard(),
                  const SizedBox(height: 16),
                  _buildPhotoSection(),
                  const SizedBox(height: 16),
                  _buildServiceDetailsSection(),
                  const SizedBox(height: 24),
                  _buildCompleteServiceButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
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
          'Servicio en Sitio',
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

  Widget _buildClientInfoCard() {
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
                    widget.serviceRequest.user?.name ?? 'Cliente',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Servicio de Recarga Eléctrica',
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
                      'EN SITIO',
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

  Widget _buildServiceProgressCard() {
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
                  'Progreso del Servicio',
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
                  label: const Text('Iniciar Servicio de Carga'),
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
                            'Servicio iniciado: ${_formatTime(_serviceStartTime!)}',
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
                  _buildServiceTimer(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTimer() {
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
                'Tiempo transcurrido: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
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

  Widget _buildPhotoSection() {
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
                  'Documentación Fotográfica',
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
              title: 'Foto del Vehículo',
              subtitle: 'Captura una foto del vehículo del cliente',
              photo: _vehiclePhoto,
              onTap: () => _takePhoto('vehicle'),
              icon: Icons.directions_car,
              color: AppColors.info,
              uploaded: _vehiclePhotoUploaded, // ✅ AGREGAR
            ),

            const SizedBox(height: 12),

            // Foto antes de la carga
            _buildPhotoCard(
              title: 'Antes de la Carga',
              subtitle: 'Estado inicial de la batería',
              photo: _beforePhoto,
              onTap: () => _takePhoto('before'),
              icon: Icons.battery_0_bar,
              color: AppColors.warning,
              uploaded: _beforePhotoUploaded, // ✅ AGREGAR
            ),

            const SizedBox(height: 12),

            // Foto después de la carga
            _buildPhotoCard(
              title: 'Después de la Carga',
              subtitle: 'Estado final de la batería',
              photo: _afterPhoto,
              onTap: () => _takePhoto('after'),
              icon: Icons.battery_full,
              color: AppColors.success,
              enabled: _serviceStarted,
              uploaded: _afterPhotoUploaded, // ✅ AGREGAR
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
    bool uploaded = false, // Nuevo parámetro
  }) {
    // Determinar si la foto está completa (archivo local O subida al servidor)
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
                        ? 'Foto guardada en servidor'
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
              // Mostrar miniatura si hay archivo local
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
              // Mostrar icono de "subida" si no hay archivo local pero está en servidor
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
              // Mostrar icono de cámara si no hay foto
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

  Widget _buildServiceDetailsSection() {
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
                  'Detalles del Servicio',
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
                LengthLimitingTextInputFormatter(
                    2), // This line limits the input to 2 characters
              ],
              decoration: InputDecoration(
                labelText: 'Nivel de batería inicial (%)',
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
                LengthLimitingTextInputFormatter(
                    3), // This line limits the input to 2 characters
              ],
              decoration: InputDecoration(
                labelText: 'Tiempo de carga (minutos)',
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
                labelText: 'Notas adicionales',
                hintText: 'Observaciones sobre el servicio...',
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

  Widget _buildCompleteServiceButton() {
    // ✅ CORREGIR: Considerar tanto archivos locales como fotos subidas
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
          _isLoading ? 'Completando...' : 'Completar Servicio',
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

          // ✅ DETECTAR FOTOS SUBIDAS CORRECTAMENTE
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
    }
  }

  // NUEVO: Método para guardar progreso automáticamente
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

  // NUEVO: Callback para cuando cambian los campos de texto
  void _onTextFieldChanged() {
    // Guardar con un pequeño delay para evitar muchas llamadas
    Timer(const Duration(milliseconds: 1000), () {
      _saveProgress();
    });
  }

// ✅ CORREGIR _startService - AGREGAR _saveProgress()
  void _startService() async {
    try {
      await TechnicianService.updateServiceStatus(
          widget.serviceRequest.id, 'charging',
          notes: 'Servicio de carga iniciado');

      setState(() {
        _serviceStarted = true;
        _serviceStartTime = DateTime.now();
      });

      // ✅ AGREGAR: Guardar progreso después de iniciar servicio
      await _saveProgress();

      HapticFeedback.lightImpact();
      _showSuccessSnackbar('Servicio de carga iniciado');
    } catch (e) {
      _showErrorSnackbar('Error al iniciar servicio: $e');
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

        // ✅ SUBIR LA FOTO INMEDIATAMENTE AL SERVIDOR
        try {
          final success = await TechnicianService.uploadServicePhotos(
            serviceId: widget.serviceRequest.id,
            photos: [File(image.path)],
            photoTypes: [type], // 'vehicle', 'before', o 'after'
          );

          if (success) {
            print('✅ Foto $type subida exitosamente');
          } else {
            print('❌ Error subiendo foto $type');
            _showErrorSnackbar('Error al subir la foto');
          }
        } catch (e) {
          print('❌ Error en upload de foto: $e');
          _showErrorSnackbar('Error al subir la foto: $e');
        }

        // Guardar progreso después de subir la foto
        await _saveProgress();

        HapticFeedback.lightImpact();
        _showSuccessSnackbar('Foto capturada y guardada exitosamente');
      }
    } catch (e) {
      _showErrorSnackbar('Error al tomar foto: $e');
    }
  }

  Future<void> _completeService() async {
    setState(() => _isLoading = true);

    try {
      // Preparar datos para guardar
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

      // Guardar fotos y detalles del servicio
      await TechnicianService.saveServiceDetails(
        serviceId: widget.serviceRequest.id,
        initialBatteryLevel: int.tryParse(_batteryLevelController.text),
        chargeTimeMinutes: int.tryParse(_chargeTimeController.text),
        serviceNotes:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        photos: photos.isNotEmpty ? photos : null,
        photoTypes: photoTypes.isNotEmpty ? photoTypes : null,
      );

      // Actualizar estado del servicio a completado
      await TechnicianService.updateServiceStatus(
          widget.serviceRequest.id, 'completed',
          notes: _buildServiceNotes());

      HapticFeedback.heavyImpact();

      // Mostrar diálogo de confirmación
      _showCompletionDialog();
    } catch (e) {
      _showErrorSnackbar('Error al completar servicio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _buildServiceNotes() {
    final buffer = StringBuffer();
    buffer.writeln('Servicio completado exitosamente');

    if (_batteryLevelController.text.isNotEmpty) {
      buffer.writeln(
          'Nivel inicial de batería: ${_batteryLevelController.text}%');
    }

    if (_chargeTimeController.text.isNotEmpty) {
      buffer.writeln('Tiempo de carga: ${_chargeTimeController.text} minutos');
    }

    if (_notesController.text.isNotEmpty) {
      buffer.writeln('Notas: ${_notesController.text}');
    }

    buffer.writeln(
        'Fotos documentadas: ${_vehiclePhoto != null ? '✓' : '✗'} Vehículo, ${_beforePhoto != null ? '✓' : '✗'} Antes, ${_afterPhoto != null ? '✓' : '✗'} Después');

    return buffer.toString();
  }

  void _showCompletionDialog() {
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
            const Expanded(child: Text('¡Servicio Completado!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'El servicio de recarga ha sido completado exitosamente.',
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
                'El cliente recibirá una notificación y podrá calificar tu servicio.',
                style: GoogleFonts.inter(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Cerrar diálogo primero
              Navigator.of(context).pop();

              // ✅ NAVEGAR AL BOTTOM NAV Y LIMPIAR STACK COMPLETO
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => BottomNavBar(), // Tu widget principal
                ),
                (route) => false, // Elimina todas las rutas anteriores
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
              'Continuar',
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
    final clientPhone = widget.serviceRequest.user?.phone;
    if (clientPhone != null && clientPhone.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: clientPhone);
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          _showErrorSnackbar('No se pudo abrir la aplicación de teléfono');
        }
      } catch (e) {
        _showErrorSnackbar('Error al intentar llamar: $e');
      }
    } else {
      _showErrorSnackbar('No hay número de teléfono disponible');
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
    // ✅ GUARDAR PROGRESO FINAL AL SALIR
    _saveProgress();

    // ✅ CORREGIR: Usar guiones bajos, no asteriscos
    _batteryLevelController.removeListener(_onTextFieldChanged);
    _chargeTimeController.removeListener(_onTextFieldChanged);
    _notesController.removeListener(_onTextFieldChanged);

    _notesController.dispose();
    _batteryLevelController.dispose();
    _chargeTimeController.dispose();
    super.dispose();
  }
}
