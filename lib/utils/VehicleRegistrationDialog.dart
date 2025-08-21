import 'package:flutter/material.dart';
import 'package:Voltgo_app/data/services/TechnicianService.dart'; // Asegúrate de que esta ruta sea correcta
import 'package:Voltgo_app/ui/color/app_colors.dart'; // Asegúrate de que esta ruta sea correcta

class VehicleRegistrationDialog extends StatefulWidget {
  final VoidCallback onVehicleRegistered;

  const VehicleRegistrationDialog({
    super.key,
    required this.onVehicleRegistered,
  });

  @override
  State<VehicleRegistrationDialog> createState() =>
      _VehicleRegistrationDialogState();
}

class _VehicleRegistrationDialogState extends State<VehicleRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para los campos del formulario
  final _makeController =
      TextEditingController(); // CORREGIDO: de _brandController a _makeController
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _connectorTypeController =
      TextEditingController(); // NUEVO: Controlador para el conector

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _connectorTypeController.dispose(); // NUEVO: Dispose del nuevo controlador
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        // CORRECCIÓN CLAVE: El mapa debe coincidir con la validación de Laravel
        final vehicleData = {
          'make': _makeController.text, // Clave 'make', no 'brand'
          'model': _modelController.text,
          'year': _yearController.text,
          // 'plate' y 'color' no son requeridos por tu backend, pero los puedes enviar si los necesitas
          'plate': _plateController.text,
          'color': _colorController.text,
          'connector_type':
              _connectorTypeController.text, // NUEVO: Campo de conector añadido
        };

        await TechnicianService.registerVehicle(vehicleData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo registrado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onVehicleRegistered();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Mostramos el error real que viene del backend
            content:
                Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Registra tu Vehículo',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ... (Texto de bienvenida)
              const SizedBox(height: 20),
              // CORREGIDO: usa el controlador correcto y la etiqueta 'Marca'
              _buildTextFormField(
                  controller: _makeController,
                  label: 'Marca',
                  icon: Icons.directions_car),
              const SizedBox(height: 12),
              _buildTextFormField(
                  controller: _modelController,
                  label: 'Modelo',
                  icon: Icons.car_rental),
              const SizedBox(height: 12),
              _buildTextFormField(
                  controller: _yearController,
                  label: 'Año',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              // NUEVO: Campo para el tipo de conector
              _buildTextFormField(
                  controller: _connectorTypeController,
                  label: 'Tipo de Conector',
                  icon: Icons.electrical_services),
              const SizedBox(height: 12),
              _buildTextFormField(
                  controller: _plateController,
                  label: 'Placa',
                  icon: Icons.pin),
              const SizedBox(height: 12),
              _buildTextFormField(
                  controller: _colorController,
                  label: 'Color',
                  icon: Icons.color_lens),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        SizedBox(
          width: double.infinity,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _submitForm,
                  child: const Text('Registrar Vehículo'),
                ),
        ),
      ],
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
