import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Voltgo_app/data/models/User/ServiceRequestModel.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:Voltgo_app/l10n/app_localizations.dart'; // ✅ AGREGAR IMPORT

class IncomingRequestDialog extends StatefulWidget {
  final ServiceRequestModel serviceRequest;
  
  const IncomingRequestDialog({Key? key, required this.serviceRequest})
      : super(key: key);

  @override
  _IncomingRequestDialogState createState() => _IncomingRequestDialogState();
}

class _IncomingRequestDialogState extends State<IncomingRequestDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getEstimatedTime() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    final distance = widget.serviceRequest.distanceKm;
    // Estimación: 30 km/h promedio en ciudad + tiempo de servicio
    final travelMinutes = (distance / 30 * 60).round();
    final serviceMinutes = 45; // Tiempo promedio de servicio
    final totalMinutes = travelMinutes + serviceMinutes;
    
    if (totalMinutes < 60) {
      return '$totalMinutes ${l10n.minutes}'; // ✅ CAMBIAR
    } else {
      final hours = totalMinutes ~/ 60;
      final remainingMinutes = totalMinutes % 60;
      return '${hours}${l10n.hours} ${remainingMinutes}${l10n.minutes}'; // ✅ CAMBIAR
    }
  }

  String _getDistanceDescription() {
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    final distance = widget.serviceRequest.distanceKm;
    if (distance < 2) return l10n.veryClose; // ✅ CAMBIAR
    if (distance < 5) return l10n.close; // ✅ CAMBIAR
    if (distance < 10) return l10n.mediumDistance; // ✅ CAMBIAR
    return l10n.far; // ✅ CAMBIAR
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
    final l10n = AppLocalizations.of(context); // ✅ AGREGAR
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- Header ---
                            Text(
                              l10n.newRequest, // ✅ CAMBIAR
                              style: GoogleFonts.inter(
                                color: AppColors.textOnPrimary.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // --- Earnings, Distance and Time Row ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoColumn(
                                  l10n.earnings, // ✅ CAMBIAR
                                  '\$${widget.serviceRequest.estimatedEarnings.toStringAsFixed(2)}',
                                  Icons.attach_money,
                                  Colors.green,
                                ),
                                _buildInfoColumn(
                                  l10n.distance, // ✅ CAMBIAR
                                  '${widget.serviceRequest.distanceKm.toStringAsFixed(1)} km',
                                  Icons.near_me,
                                  _getDistanceColor(),
                                  subtitle: _getDistanceDescription(),
                                ),
                                _buildInfoColumn(
                                  l10n.estimatedTime, // ✅ CAMBIAR
                                  _getEstimatedTime(),
                                  Icons.access_time,
                                  Colors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // --- Service Details Card ---
                            Card(
                              elevation: 4,
                              shadowColor: AppColors.gray300.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    // Client info
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: AppColors.lightGrey,
                                          child: Icon(
                                            Icons.person,
                                            size: 24,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.serviceRequest.user?.name ?? l10n.client, // ✅ CAMBIAR
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '4.9',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(Icons.verified_user,
                                                      color: Colors.green, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    l10n.verified, // ✅ CAMBIAR
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20, color: AppColors.gray300),
                                    // Location
                                    Row(
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
                                                l10n.serviceLocation, // ✅ CAMBIAR
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Lat: ${widget.serviceRequest.requestLat?.toStringAsFixed(4)}, '
                                                'Lng: ${widget.serviceRequest.requestLng?.toStringAsFixed(4)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            // Abrir mapa o navegación
                                          },
                                          icon: Icon(
                                            Icons.navigation,
                                            color: AppColors.brandBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // --- Action Buttons ---
                            Row(
                              children: [
                                Expanded(
                                  child: _AnimatedButton(
                                    text: l10n.reject, // ✅ CAMBIAR
                                    icon: Icons.close,
                                    color: AppColors.error,
                                    onPressed: () => Navigator.pop(context, false),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _AnimatedButton(
                                    text: l10n.accept, // ✅ CAMBIAR
                                    icon: Icons.check,
                                    color: Colors.green,
                                    onPressed: () => Navigator.pop(context, true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Close button
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _AnimatedButton(
                        text: '',
                        icon: Icons.close,
                        color: AppColors.gray300,
                        onPressed: () => Navigator.pop(context, false),
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

  Widget _buildInfoColumn(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textOnPrimary.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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

// ✅ CORRECCIÓN DE ERRORES DE SINTAXIS EN _AnimatedButton
class _AnimatedButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState(); // ✅ CORREGIR
}

class _AnimatedButtonState extends State<_AnimatedButton> // ✅ CORREGIR
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller); // ✅ CORREGIR
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
          padding: widget.text.isEmpty
              ? const EdgeInsets.all(8.0)
              : const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.8)],
            ),
            borderRadius:
                BorderRadius.circular(widget.text.isEmpty ? 24.0 : 12.0),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: AppColors.textOnPrimary,
                size: widget.text.isEmpty ? 24 : 20,
              ),
              if (widget.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}