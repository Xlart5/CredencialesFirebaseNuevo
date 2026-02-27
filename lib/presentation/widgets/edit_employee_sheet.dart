import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/models/employee_model.dart';
import '../../config/theme/app_colors.dart';
import '../../config/provider/employee_provider.dart';

void showEditEmployeeSheet(BuildContext context, Employee emp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditEmployeeSheet(employee: emp),
  );
}

class EditEmployeeSheet extends StatefulWidget {
  final Employee employee;
  const EditEmployeeSheet({super.key, required this.employee});

  @override
  State<EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends State<EditEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _ciCtrl;
  late TextEditingController _celularCtrl;

  // 🔥 Convertimos estos en variables String simples en lugar de Controladores
  String? _selectedCargo;
  String? _selectedUnidad;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.employee.nombreCompleto);
    _ciCtrl = TextEditingController(text: widget.employee.ci);
    _celularCtrl = TextEditingController(text: widget.employee.celular ?? "");

    // Asignamos los valores iniciales que vienen de Firebase
    _selectedCargo = widget.employee.cargo.isNotEmpty
        ? widget.employee.cargo
        : null;
    _selectedUnidad = widget.employee.unidad.isNotEmpty
        ? widget.employee.unidad
        : null;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciCtrl.dispose();
    _celularCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final nuevosDatos = {
      'nombre': _nombreCtrl.text.trim(),
      'ci': _ciCtrl.text.trim(),
      'carnetIdentidad': _ciCtrl.text.trim(),
      'celular': _celularCtrl.text.trim(),
      'cargo': _selectedCargo ?? '', // 🔥 Guardamos el seleccionado
      'unidad': _selectedUnidad ?? '', // 🔥 Guardamos el seleccionado
    };

    final provider = context.read<EmployeeProvider>();
    bool success = await provider.updateEmployee(
      widget.employee.ci,
      nuevosDatos,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Datos actualizados correctamente."
                : "Error al guardar los cambios.",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // 🔥 Leemos las listas disponibles en tiempo real desde tu Provider
    final provider = context.watch<EmployeeProvider>();
    List<String> listaCargos = provider.cargosDisponibles.toList();
    List<String> listaUnidades = provider.unidadesDisponibles.toList();

    return Container(
      padding: EdgeInsets.only(
        top: 25,
        left: 25,
        right: 25,
        bottom: bottomInset + 25,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Editar Personal",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField("Nombre Completo", _nombreCtrl, Icons.person),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField("C.I.", _ciCtrl, Icons.badge),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      "Celular",
                      _celularCtrl,
                      Icons.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 🔥 DROPDOWN PARA CARGO
              _buildDropdownField(
                label: "Cargo / Rol",
                currentValue: _selectedCargo,
                items: listaCargos,
                icon: Icons.work,
                onChanged: (val) => setState(() => _selectedCargo = val),
              ),
              const SizedBox(height: 15),

              // 🔥 DROPDOWN PARA UNIDAD
              _buildDropdownField(
                label: "Unidad / Departamento",
                currentValue: _selectedUnidad,
                items: listaUnidades,
                icon: Icons.business,
                onChanged: (val) => setState(() => _selectedUnidad = val),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSaving ? null : _guardarCambios,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Guardar Cambios",
                          style: TextStyle(
                            color: Colors.black,
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
    );
  }

  // Widget para Cajas de Texto (Nombre, CI, Celular)
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
      ),
      validator: (v) => v!.trim().isEmpty ? 'Campo requerido' : null,
    );
  }

  // 🔥 NUEVO WIDGET: Dropdown hermoso y seguro
  Widget _buildDropdownField({
    required String label,
    required String? currentValue,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    // Truco de seguridad: Si la persona tiene un cargo que "ya no existe" o se escribió mal,
    // lo agregamos temporalmente a la lista para que Flutter no crashee.
    if (currentValue != null &&
        currentValue.isNotEmpty &&
        !items.contains(currentValue)) {
      items.add(currentValue);
    }

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
      ),
      items: items.map((String val) {
        return DropdownMenuItem(
          value: val,
          child: Text(val, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Seleccione una opción' : null,
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryDark),
    );
  }
}
