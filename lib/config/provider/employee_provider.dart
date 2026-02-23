import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_model.dart';

class EmployeeProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;

  // --- VARIABLES PARA FILTROS RÁPIDOS ---
  String _searchQuery = '';
  String? _selectedUnidadFilter;
  String? _selectedEstadoFilter;

  // Sets para guardar los valores únicos
  final Set<String> _unidadesDisponibles = {};
  final Set<String> _estadosDisponibles = {};

  // =====================================
  // SELECCIÓN MÚLTIPLE PARA IMPRESIÓN
  // =====================================
  final Set<Employee> _selectedForPrint = {};
  Set<Employee> get selectedForPrint => _selectedForPrint;

  // =====================================
  // GETTERS GENERALES
  // =====================================
  List<Employee> get allEmployees => _allEmployees;
  String get searchQuery => _searchQuery;
  List<Employee> get employees => _filteredEmployees;
  bool get isLoading => _isLoading;
  Set<String> get unidadesDisponibles => _unidadesDisponibles;
  Set<String> get estadosDisponibles => _estadosDisponibles;
  String? get selectedUnidadFilter => _selectedUnidadFilter;
  String? get selectedEstadoFilter => _selectedEstadoFilter;

  // KPIs
  int get totalEmployees => _allEmployees.length;
  int get printedCredentials => _allEmployees
      .where((e) => e.estadoActual.toUpperCase() == "CREDENCIAL IMPRESO")
      .length;
  int get pendingRequests => _allEmployees
      .where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO")
      .length;

  // =====================================
  // INICIAR ESCUCHA EN TIEMPO REAL (FIREBASE)
  // =====================================
  void fetchEmployees() {
    _isLoading = true;
    notifyListeners();

    // Esto crea un túnel constante con Firestore. Si alguien añade un empleado, se actualiza solo.
    _db
        .collection('personal')
        .snapshots()
        .listen(
          (snapshot) {
            _allEmployees = snapshot.docs.map((doc) {
              return Employee.fromFirestore(doc.data(), doc.id);
            }).toList();

            _actualizarListasSecundarias();
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            print("Error escuchando Firebase: $error");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _actualizarListasSecundarias() {
    _unidadesDisponibles.clear();
    _estadosDisponibles.clear();
    for (var emp in _allEmployees) {
      if (emp.unidad.isNotEmpty) _unidadesDisponibles.add(emp.unidad);
      if (emp.estadoActual.isNotEmpty)
        _estadosDisponibles.add(emp.estadoActual);
    }
    _applyFilters();
  }

  void _applyFilters() {
    _filteredEmployees = _allEmployees.where((emp) {
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final lowerQuery = _searchQuery.toLowerCase();
        matchesSearch =
            emp.nombreCompleto.toLowerCase().contains(lowerQuery) ||
            emp.carnetIdentidad.contains(_searchQuery);
      }
      bool matchesUnidad = true;
      if (_selectedUnidadFilter != null) {
        matchesUnidad = emp.unidad == _selectedUnidadFilter;
      }
      bool matchesEstado = true;
      if (_selectedEstadoFilter != null) {
        matchesEstado = emp.estadoActual == _selectedEstadoFilter;
      }
      return matchesSearch && matchesUnidad && matchesEstado;
    }).toList();

    notifyListeners();
  }

  // =====================================
  // ACCIONES DE LA INTERFAZ
  // =====================================
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void toggleUnidadFilter(String unidad) {
    _selectedUnidadFilter = _selectedUnidadFilter == unidad ? null : unidad;
    _applyFilters();
  }

  void toggleEstadoFilter(String estado) {
    _selectedEstadoFilter = _selectedEstadoFilter == estado ? null : estado;
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedUnidadFilter = null;
    _selectedEstadoFilter = null;
    _applyFilters();
  }

  // Selección múltiple
  void toggleSelection(Employee emp) {
    if (_selectedForPrint.contains(emp)) {
      _selectedForPrint.remove(emp);
    } else {
      _selectedForPrint.add(emp);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedForPrint.clear();
    notifyListeners();
  }

  // =====================================
  // ACTUALIZAR ESTADO (IMPRESIÓN) EN FIREBASE
  // =====================================
  Future<bool> markAsPrinted(Employee emp) async {
    try {
      await _db.collection('personal').doc(emp.ci).update({
        'estadoActual': 'CREDENCIAL IMPRESO',
      });
      // No necesitamos actualizar la lista manualmente, el 'snapshot().listen' lo hará solo
      return true;
    } catch (e) {
      print('Error al actualizar Firebase: $e');
      return false;
    }
  }

  // =====================================
  // ELIMINAR EMPLEADO EN FIREBASE
  // =====================================
  Future<bool> deleteEmployee(int idStr, String carnet) async {
    try {
      await _db.collection('personal').doc(carnet).delete();
      return true;
    } catch (e) {
      print('Error al eliminar en Firebase: $e');
      return false;
    }
  }

  // =====================================
  // GETTERS PARA IMPRESIÓN (print_screen)
  // =====================================
  List<Employee> get pendingPrintingEmployees => _allEmployees
      .where((e) => e.estadoActual.toUpperCase() == "PERSONAL REGISTRADO")
      .toList();

  // =====================================
  // VARIABLES PARA REPORTES
  // =====================================
  List<dynamic> _reportData = [];
  List<dynamic> get reportData => _reportData;
  int get reportTotal => _reportData.length;

  // =====================================
  // BUSCAR POR CIRCUNSCRIPCIÓN (FIREBASE)
  // =====================================
  Future<void> fetchReportePorCircunscripcion(String cir) async {
    _isLoading = true;
    _reportData = [];
    notifyListeners();

    try {
      // Usamos Firestore para buscar directamente a los de esa circunscripción
      final snapshot = await _db
          .collection('personal')
          // ATENCIÓN: Asegúrate de que este sea el nombre exacto del campo en Firestore
          .where('nroCircunscripcion', isEqualTo: cir)
          .get();

      // Mapeamos los resultados para que tu ReportsScreen los lea como si fuera el JSON antiguo
      _reportData = snapshot.docs.map((doc) {
        final data = doc.data();
        // Inyectamos el Carnet de Identidad por si tu reporte lo necesita
        data['carnetIdentidad'] = data['ci'] ?? doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error Conexión Reporte Firebase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiarReporte() {
    _reportData = [];
    notifyListeners();
  }
}
