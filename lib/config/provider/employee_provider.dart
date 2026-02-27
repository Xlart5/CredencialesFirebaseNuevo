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
  final Set<String> _cargosDisponibles = {};

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
  Set<String> get cargosDisponibles => _cargosDisponibles;

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
    _cargosDisponibles.clear(); // 🔥 Limpiamos antes de llenar

    for (var emp in _allEmployees) {
      if (emp.unidad.isNotEmpty) _unidadesDisponibles.add(emp.unidad);
      if (emp.estadoActual.isNotEmpty)
        _estadosDisponibles.add(emp.estadoActual);
      if (emp.cargo.isNotEmpty)
        _cargosDisponibles.add(emp.cargo); // 🔥 Extraemos el cargo
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
      return true;
    } catch (e) {
      print('Error al actualizar Firebase: $e');
      return false;
    }
  }

  // =====================================
  // 🔥 NUEVO: FINALIZAR CONTRATOS EN MASA (CERTIFICADOS)
  // =====================================
  Future<bool> terminarContratosMasivo(List<Employee> empleados) async {
    try {
      WriteBatch batch = _db.batch(); // Agrupa todas las operaciones en 1 sola

      for (var emp in empleados) {
        DocumentReference docRef = _db.collection('personal').doc(emp.ci);
        batch.update(docRef, {'estadoActual': 'CONTRATO TERMINADO'});
      }

      await batch.commit(); // Ejecutamos el guardado masivo
      return true;
    } catch (e) {
      print('Error en batch de contratos: $e');
      return false;
    }
  }

  // =====================================
  // 🔥 PASAR A "PERSONA ACTIVA" MASIVO
  // =====================================
  Future<bool> marcarComoActivoMasivo(List<Employee> empleados) async {
    try {
      WriteBatch batch = _db.batch();
      for (var emp in empleados) {
        DocumentReference docRef = _db.collection('personal').doc(emp.ci);
        batch.update(docRef, {'estadoActual': 'PERSONA ACTIVA'});
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('Error en batch de activar personal: $e');
      return false;
    }
  }

  // =====================================
  // 🔥 PASAR A "CREDENCIAL DEVUELTO" MASIVO
  // =====================================
  Future<bool> marcarCredencialDevueltoMasivo(List<Employee> empleados) async {
    try {
      WriteBatch batch = _db.batch();
      for (var emp in empleados) {
        DocumentReference docRef = _db.collection('personal').doc(emp.ci);
        batch.update(docRef, {'estadoActual': 'CREDENCIAL DEVUELTO'});
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('Error en batch de devolver credencial: $e');
      return false;
    }
  }

  // =====================================
  // 🔥 PASAR A "CONTRATO FINALIZADO" MASIVO
  // =====================================
  Future<bool> marcarContratoFinalizadoMasivo(List<Employee> empleados) async {
    try {
      WriteBatch batch = _db.batch();
      for (var emp in empleados) {
        DocumentReference docRef = _db.collection('personal').doc(emp.ci);
        batch.update(docRef, {
          'estadoActual': 'CONTRATO FINALIZADO', // Nuevo estado
        });
      }
      await batch.commit();
      return true;
    } catch (e) {
      print('Error en batch de finalizar contrato: $e');
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

  Future<void> fetchReportePorCircunscripcion(String cir) async {
    _isLoading = true;
    _reportData = [];
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('personal')
          .where('nroCircunscripcion', isEqualTo: cir)
          .get();

      _reportData = snapshot.docs.map((doc) {
        final data = doc.data();
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

  Future<bool> updateEmployee(
    String documentId,
    Map<String, dynamic> newData,
  ) async {
    try {
      // documentId generalmente es el CI de la persona
      await _db.collection('personal').doc(documentId).update(newData);
      return true;
    } catch (e) {
      print('Error al actualizar empleado: $e');
      return false;
    }
  }
}
