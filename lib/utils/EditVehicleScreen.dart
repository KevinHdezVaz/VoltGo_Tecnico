import 'dart:convert';
import 'package:Voltgo_app/data/services/TechnicianService.dart';
import 'package:Voltgo_app/ui/color/app_colors.dart';
import 'package:flutter/material.dart';

class EditVehicleScreen extends StatefulWidget {
  const EditVehicleScreen({super.key});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Controladores para los campos del formulario
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _connectorTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _connectorTypeController.dispose();
    super.dispose();
  }

  // En EditVehicleScreen.dart

  Future<void> _loadVehicleData() async {
    try {
      final profile = await TechnicianService.getProfile();

      if (profile['vehicle_details'] != null) {
        // --- INICIO DE LA CORRECCIÓN ---
        // La API ya nos da un mapa, no necesitamos decodificarlo de nuevo.
        // Simplemente asignamos el mapa directamente a nuestra variable.
        final vehicleData = profile['vehicle_details'] as Map<String, dynamic>;
        // --- FIN DE LA CORRECCIÓN ---

        setState(() {
          // Usamos .toString() para asegurar que incluso si el año es un número, se asigne correctamente al controlador de texto.
          _makeController.text = vehicleData['make'] ?? '';
          _modelController.text = vehicleData['model'] ?? '';
          _yearController.text = vehicleData['year']?.toString() ?? '';
          _plateController.text = vehicleData['plate'] ?? '';
          _colorController.text = vehicleData['color'] ?? '';
          _connectorTypeController.text = vehicleData['connector_type'] ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error al cargar los datos: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      try {
        final vehicleData = {
          'make': _makeController.text,
          'model': _modelController.text,
          'year': _yearController.text,
          'plate': _plateController.text,
          'color': _colorController.text,
          'connector_type': _connectorTypeController.text,
        };

        // Llama al nuevo método del servicio para actualizar
        await TechnicianService.updateVehicle(vehicleData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo actualizado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );

        // Regresa a la pantalla anterior
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Vehículo'),
        backgroundColor: AppColors.brandBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextFormField(
                            controller: _makeController,
                            label: 'Marca',
                            icon: Icons.directions_car),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                            controller: _modelController,
                            label: 'Modelo',
                            icon: Icons.car_rental),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                            controller: _yearController,
                            label: 'Año',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                            controller: _connectorTypeController,
                            label: 'Tipo de Conector',
                            icon: Icons.electrical_services),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                            controller: _plateController,
                            label: 'Placa',
                            icon: Icons.pin),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                            controller: _colorController,
                            label: 'Color',
                            icon: Icons.color_lens),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: _isSaving
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  icon: const Icon(Icons.save),
                                  label: const Text('Guardar Cambios'),
                                  onPressed: _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, introduce la $label.';
        }
        return null;
      },
    );
  }
}
