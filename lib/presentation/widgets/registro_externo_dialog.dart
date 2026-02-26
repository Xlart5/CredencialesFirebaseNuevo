import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/provider/externos_provider.dart';

class RegistroExternoDialog extends StatefulWidget {
  final String qrEscaneado; // Ej: EXT-PRENSA-123456

  const RegistroExternoDialog({super.key, required this.qrEscaneado});

  @override
  State<RegistroExternoDialog> createState() => _RegistroExternoDialogState();
}

class _RegistroExternoDialogState extends State<RegistroExternoDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _ciCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();

  bool _isSubmitting = false;

  // Extraemos el tipo de externo del QR para darle color a la interfaz
  String get _tipoExterno {
    List<String> partes = widget.qrEscaneado.split('-');
    return partes.length >= 2 ? partes[1].toUpperCase() : "GENERAL";
  }

  // Colores dinámicos según el tipo (Basado en tus ideas de mockups)
  Color get _colorTipo {
    switch (_tipoExterno) {
      case 'PRENSA':
        return Colors.orange;
      case 'OBSERVADOR':
        return Colors.blue;
      case 'DELEGADO':
        return Colors.purple;
      case 'CANDIDATO':
        return Colors.redAccent;
      default:
        return Colors.teal; // Público General
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<ExternosProvider>();

    // Guardamos directo a Firebase
    bool success = await provider.registrarPersonaNueva(
      qrId: widget.qrEscaneado,
      nombre: _nombreCtrl.text.trim(),
      ci: _ciCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (context.mounted) {
      if (success) {
        Navigator.pop(context, true); // Cerramos y avisamos que fue un éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_tipoExterno registrado y con acceso permitido.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar. Intente de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400, // Ancho perfecto para tablet o PC en recepción
        padding: const EdgeInsets.all(
          0,
        ), // Padding 0 para que el header pegue a los bordes
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HEADER DINÁMICO (Cambia de color según el QR) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _colorTipo,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: Colors.white, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "NUEVO REGISTRO",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _tipoExterno,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // --- FORMULARIO EXPRESS ---
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "QR: ${widget.qrEscaneado}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CAMPO 1: NOMBRE COMPLETO
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        "Nombre Completo",
                        Icons.person_outline,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 15),

                    // CAMPO 2: CARNET DE IDENTIDAD
                    TextFormField(
                      controller: _ciCtrl,
                      decoration: _inputDecoration(
                        "Carnet de Identidad (CI)",
                        Icons.badge_outlined,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 15),

                    // CAMPO 3: TELÉFONO
                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        "Número de Teléfono",
                        Icons.phone_android,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 25),

                    // BOTÓN DE GUARDAR Y DAR ACCESO
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorTipo,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _registrar,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Registrar y Permitir Acceso",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _colorTipo, width: 2),
      ),
    );
  }
}
