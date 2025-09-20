import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart';
import 'package:geocoding/geocoding.dart';

class IncomingRequestDialog extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  
  const IncomingRequestDialog({Key? key, required this.serviceRequest})
      : super(key: key);  

  @override
  _IncomingRequestDialogState createState() {
    print('🚗 VEHICLE_DEBUG: Dialog constructor - clientVehicle is null: ${serviceRequest.clientVehicle == null}');
    if (serviceRequest.clientVehicle != null) {
      print('🚗 VEHICLE_DEBUG: Dialog constructor - Vehicle: ${serviceRequest.clientVehicle!.make} ${serviceRequest.clientVehicle!.model}');
    }
    return _IncomingRequestDialogState();
  }
 }

class _IncomingRequestDialogState extends State<IncomingRequestDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _locationAddress = '';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _getAddressFromCoordinates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromCoordinates() async {
    try {
      if (widget.serviceRequest.requestLat != null && 
          widget.serviceRequest.requestLng != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          widget.serviceRequest.requestLat!,
          widget.serviceRequest.requestLng!,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Construir dirección más completa y legible
          String address = '';
          if (place.street != null && place.street!.isNotEmpty) {
            address += place.street!;
          }
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            address += ' ${place.subThoroughfare!}';
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address += ', ${place.subLocality!}';
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            address += ', ${place.locality!}';
          }
          
          setState(() {
            _locationAddress = address.isNotEmpty ? address : 'Ubicación disponible';
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _locationAddress = 'Ubicación no disponible';
        _isLoadingAddress = false;
      });
    }
  }

  String _getEstimatedTime() {
    final l10n = AppLocalizations.of(context);
    final distance = widget.serviceRequest.distanceKm;
    final travelMinutes = (distance / 30 * 60).round();
    final serviceMinutes = 45;
    final totalMinutes = travelMinutes + serviceMinutes;
    
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    } else {
      final hours = totalMinutes ~/ 60;
      final remainingMinutes = totalMinutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  String _getDistanceDescription() {
    final l10n = AppLocalizations.of(context);
    final distance = widget.serviceRequest.distanceKm;
    if (distance < 2) return l10n.veryClose;
    if (distance < 5) return l10n.close;
    if (distance < 10) return l10n.mediumDistance;
    return l10n.far;
  }

  // ✅ MÉTODO ACTUALIZADO: Usar datos reales del vehículo
String _getClientVehicleInfo() {
  print('🚗 VEHICLE_DEBUG: Dialog - Getting client vehicle info');
  print('🚗 VEHICLE_DEBUG: Dialog - clientVehicle is null: ${widget.serviceRequest.clientVehicle == null}');
  
  if (widget.serviceRequest.clientVehicle != null) {
    final vehicle = widget.serviceRequest.clientVehicle!;
    final result = '${vehicle.make} ${vehicle.model} ${vehicle.year}';
    print('🚗 VEHICLE_DEBUG: Dialog - Returning: $result');
    return result;
  }
  
  print('🚗 VEHICLE_DEBUG: Dialog - Returning fallback: Vehículo no especificado');
  return 'Vehículo no especificado';
}
  Color _getDistanceColor() {
    final distance = widget.serviceRequest.distanceKm;
    if (distance < 2) return Colors.green;
    if (distance < 5) return Colors.orange;
    if (distance < 10) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    // DEBUG: Verificar que el diálogo se esté construyendo
    print('=== DIALOG BUILD DEBUG ===');
    print('ServiceRequest ID: ${widget.serviceRequest.id}');
    print('User name: ${widget.serviceRequest.user?.name}');
    print('Raw clientVehicle: ${widget.serviceRequest.clientVehicle}');
    print('========================');
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenSize.width * 0.85, // Ancho fijo más equilibrado
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.75, // Altura más controlada
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.95),
                      AppColors.brandBlue.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- Header ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.newRequest,
                              style: GoogleFonts.inter(
                                color: AppColors.textOnPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
              
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                
                                 _buildCompactStat(
                                  '${widget.serviceRequest.distanceKm.toStringAsFixed(1)} km',
                                  l10n.distance,
                                  Icons.near_me,
                                  _getDistanceColor(),
                                ),
                                _buildVerticalDivider(),
                                _buildCompactStat(
                                  _getEstimatedTime(),
                                  l10n.time,
                                  Icons.access_time,
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // --- Service Details Card ---
                          Flexible(
                            child: Card(
                              color: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Client info
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: AppColors.primary.withOpacity(0.1),
                                          child: Icon(
                                            Icons.person,
                                            size: 26,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.serviceRequest.user?.name ?? l10n.client,
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              // ✅ AGREGAR: Información del vehículo del cliente
                                             // ✅ SECCIÓN DETALLADA DEL VEHÍCULO
const SizedBox(height: 8),
_buildVehicleDetailsSection(),
                                            
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, color: AppColors.gray300),
                                    
                                    // Location - Mejorado para mostrar dirección completa
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: AppColors.brandBlue,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.serviceLocation,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              _isLoadingAddress
                                                  ? Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 12,
                                                          height: 12,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            color: AppColors.brandBlue,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'Cargando...',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 12,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Container(
                                                      width: double.infinity,
                                                      child: Text(
                                                        _locationAddress.isEmpty 
                                                            ? 'Lat: ${widget.serviceRequest.requestLat?.toStringAsFixed(4)}, Lng: ${widget.serviceRequest.requestLng?.toStringAsFixed(4)}'
                                                            : _locationAddress,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          color: AppColors.textSecondary,
                                                          height: 1.3,
                                                        ),
                                                        maxLines: 3, // Permitir más líneas
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),

                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // --- Action Buttons ---
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  text: l10n.reject,
                                  icon: Icons.close_rounded,
                                  color: AppColors.error,
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  text: l10n.accept,
                                  icon: Icons.check_rounded,
                                  color: Colors.green,
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Close button
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textOnPrimary,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textOnPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textOnPrimary.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Agrega estos métodos a tu clase _IncomingRequestDialogState

// Método para construir la sección de detalles del vehículo
Widget _buildVehicleDetailsSection() {
      final l10n = AppLocalizations.of(context);

  final vehicle = widget.serviceRequest.clientVehicle;
  
  if (vehicle == null) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.electric_car, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(
            'Información del vehículo no disponible',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Row(
          children: [
            Icon(Icons.electric_car, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.vehicle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Detalles del vehículo en filas
        _buildVehicleDetailRow('Brand:', vehicle.make),
        const SizedBox(height: 6),
        _buildVehicleDetailRow('Model:', vehicle.model),
        
        const SizedBox(height: 6),
        _buildVehicleDetailRow('Connector:', vehicle.connectorType),
        
      
      ],
    ),
  );
}

// Método auxiliar para crear fila de detalle del vehículo
Widget _buildVehicleDetailRow(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 70,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value.isNotEmpty ? value : 'No especificado',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: value.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}


  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.textOnPrimary.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceDetail(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}