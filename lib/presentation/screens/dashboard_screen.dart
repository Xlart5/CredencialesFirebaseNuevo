import 'package:carnetizacion/config/helpers/certificate_pdf_service.dart';
import 'package:carnetizacion/config/helpers/pdf_generator_service.dart';
import 'package:carnetizacion/config/provider/employee_provider.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../config/models/employee_model.dart';
import '../widgets/kpi_card.dart';
import '../widgets/sidebar_filter.dart';
import '../widgets/employees_table.dart';
import '../widgets/side_menu.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    // 🔥 LA MAGIA: Verificamos que haya seleccionados y que TODOS hayan devuelto la credencial
    final seleccionados = provider.selectedForPrint.toList();
    // 🔥 2. CONDICIONES MÁGICAS (NUEVO FLUJO)
    final bool todosImpresos =
        seleccionados.isNotEmpty &&
        seleccionados.every(
          (emp) => emp.estadoActual.toUpperCase() == 'CREDENCIAL IMPRESO',
        );
    final bool todosActivos =
        seleccionados.isNotEmpty &&
        seleccionados.every(
          (emp) => emp.estadoActual.toUpperCase() == 'PERSONA ACTIVA',
        );
    final bool todosDevolvieron =
        seleccionados.isNotEmpty &&
        seleccionados.every(
          (emp) => emp.estadoActual.toUpperCase() == 'CREDENCIAL DEVUELTO',
        );
    final bool todosFinalizados =
        seleccionados.isNotEmpty &&
        seleccionados.every(
          (emp) => emp.estadoActual.toUpperCase() == 'CONTRATO FINALIZADO',
        );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,

      // 🔥 BOTONES FLOTANTES DINÁMICOS
      floatingActionButton: seleccionados.isEmpty
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Botón Base: Imprimir Lote
                FloatingActionButton.extended(
                  heroTag: 'btnImprimirLote',
                  backgroundColor: AppColors.primaryYellow,
                  icon: const Icon(Icons.print, color: Colors.black),
                  label: Text(
                    "Imprimir Lote (${seleccionados.length})",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    // Aquí generas tu PDF general
                    provider.clearSelection();
                  },
                ),

                // 2. BOTÓN: PASAR A ACTIVO
                if (todosImpresos) ...[
                  const SizedBox(width: 15),
                  FloatingActionButton.extended(
                    heroTag: 'btnActivar',
                    backgroundColor: Colors.blue,
                    icon: const Icon(Icons.how_to_reg, color: Colors.white),
                    label: const Text(
                      "Habilitar Personal",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        _procesarActivacion(context, seleccionados, provider),
                  ),
                ],

                // 3. BOTÓN: DEVOLVER CREDENCIAL
                if (todosActivos) ...[
                  const SizedBox(width: 15),
                  FloatingActionButton.extended(
                    heroTag: 'btnDevolver',
                    backgroundColor: Colors.orange,
                    icon: const Icon(
                      Icons.assignment_return,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Recibir Credenciales",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        _procesarDevolucion(context, seleccionados, provider),
                  ),
                ],

                // 🔥 4. BOTÓN: FINALIZAR CONTRATO (Solo si devolvieron el plástico)
                if (todosDevolvieron) ...[
                  const SizedBox(width: 15),
                  FloatingActionButton.extended(
                    heroTag: 'btnFinalizar',
                    backgroundColor:
                        Colors.redAccent, // Rojo para cierre de contrato
                    icon: const Icon(Icons.gavel, color: Colors.white),
                    label: const Text(
                      "Finalizar Contrato",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _procesarFinalizacionContrato(
                      context,
                      seleccionados,
                      provider,
                    ),
                  ),
                ],

                // 🔥 5. BOTÓN: IMPRIMIR CERTIFICADOS (Solo si el contrato está finalizado)
                if (todosFinalizados) ...[
                  const SizedBox(width: 15),
                  FloatingActionButton.extended(
                    heroTag: 'btnCertificados',
                    backgroundColor: Colors.green, // Verde premio
                    icon: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Imprimir Certificados",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        _procesarCertificados(context, seleccionados, provider),
                  ),
                ],
              ],
            ),

      drawer: const SideMenu(),

      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "CONTROL CENTRAL",
                      style: TextStyle(
                        letterSpacing: 2,
                        fontSize: 12,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Panel de Administración",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 6,
                            top: 6,
                            bottom: 6,
                            right: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1F24),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Administrador",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 2. TARJETAS KPI ---
            Row(
              children: [
                KPICard(
                  title: "TOTAL",
                  value: provider.totalEmployees.toString(),
                  subtitle: "Empleados registrados",
                  icon: Icons.people_alt_outlined,
                  badgeText: "TOTAL",
                ),
                KPICard(
                  title: "ÉXITO",
                  value: provider.printedCredentials.toString(),
                  subtitle: "Credenciales Impresas",
                  icon: Icons.print_outlined,
                  isDark: true,
                  badgeText: "IMPRESOS",
                ),
                KPICard(
                  title: "REVISIÓN",
                  value: provider.pendingRequests.toString(),
                  subtitle: "Solicitudes pendientes",
                  icon: Icons.assignment_late_outlined,
                  badgeText: "PENDIENTES",
                ),
              ],
            ),

            // --- 3. TABLA DE DATOS ---
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SidebarFilter(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: SingleChildScrollView(child: EmployeesTable()),
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

  // =====================================
  // 🔥 LÓGICA PARA GENERAR CERTIFICADOS Y FINALIZAR
  // =====================================

  // =====================================
  // 🔥 LÓGICA: HABILITAR PERSONAL (Activo)
  // =====================================
  void _procesarActivacion(
    BuildContext context,
    List<Employee> empleados,
    EmployeeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.how_to_reg, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text("¿Habilitar Personal?"),
          ],
        ),
        content: Text(
          "Se registrará la entrega de credenciales a estas ${empleados.length} personas.\n\nPasarán a estar como 'PERSONA ACTIVA' y podrán usar los escáneres de las puertas.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              Navigator.of(ctx).pop();
              bool success = await provider.marcarComoActivoMasivo(empleados);
              if (context.mounted) {
                if (success) {
                  provider.clearSelection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Personal habilitado correctamente."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Error al actualizar estado."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Sí, Habilitar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================
  // 🔥 LÓGICA: RECIBIR CREDENCIALES
  // =====================================
  void _procesarDevolucion(
    BuildContext context,
    List<Employee> empleados,
    EmployeeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.assignment_return, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("¿Recibir Credenciales?"),
          ],
        ),
        content: Text(
          "¿Confirmas que estas ${empleados.length} personas devolvieron su credencial plástica?\n\nSu estado pasará a 'CREDENCIAL DEVUELTO' y quedarán listos para sus certificados.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.of(ctx).pop();
              bool success = await provider.marcarCredencialDevueltoMasivo(
                empleados,
              );
              if (context.mounted) {
                if (success) {
                  provider.clearSelection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Credenciales devueltas correctamente."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Error al actualizar estado."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Sí, Confirmar Devolución",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================
  // 🔥 LÓGICA: FINALIZAR CONTRATO
  // =====================================
  void _procesarFinalizacionContrato(
    BuildContext context,
    List<Employee> empleados,
    EmployeeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("¿Finalizar Contrato?"),
          ],
        ),
        content: Text(
          "¿Confirmas que se ha finalizado el vínculo laboral con estas ${empleados.length} personas?\n\nPasarán al estado 'CONTRATO FINALIZADO' y quedarán listos para recibir su certificado.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              bool success = await provider.marcarContratoFinalizadoMasivo(
                empleados,
              );
              if (context.mounted) {
                if (success) {
                  provider.clearSelection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Contratos finalizados correctamente."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Error al finalizar contratos."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Sí, Finalizar Contrato",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================
  // 🔥 LÓGICA: IMPRIMIR CERTIFICADOS
  // =====================================
  // =====================================
  // 🔥 LÓGICA: IMPRIMIR CERTIFICADOS
  // =====================================
  // =====================================
  // 🔥 LÓGICA: IMPRIMIR CERTIFICADOS
  // =====================================
  void _procesarCertificados(
    BuildContext context,
    List<Employee> empleados,
    EmployeeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Imprimir Certificados"),
          ],
        ),
        content: Text(
          "Las ${empleados.length} personas seleccionadas ya tienen su contrato finalizado.\n\n¿Proceder a generar el archivo PDF con sus certificados?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.of(ctx).pop();

              // 🔥 AHORA LLAMAMOS AL NUEVO ARCHIVO EXCLUSIVO DE CERTIFICADOS
              final pdfBytes =
                  await CertificatePdfService.generateCertificadosPdf(
                    empleados,
                  );

              await Printing.layoutPdf(
                onLayout: (format) async => pdfBytes,
                name:
                    'Certificados_TED_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );

              if (context.mounted) {
                provider.clearSelection();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "🖨️ Documento de Certificados enviado a impresión.",
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: const Text(
              "Generar PDF",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
