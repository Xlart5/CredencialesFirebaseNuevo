import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unidad_model.dart';

class UnidadesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<UnidadModel> _unidades = [];
  List<CargoUnidadModel> _todosLosCargos = [];
  bool _isLoading = true;

  List<UnidadModel> get unidades => _unidades;
  bool get isLoading => _isLoading;

  // Filtrar los cargos que pertenecen a una unidad específica
  List<CargoUnidadModel> getCargosPorUnidad(int unidadId) {
    return _todosLosCargos.where((c) => c.unidadId == unidadId).toList();
  }

  // =====================================
  // 1. LEER (READ) - EN TIEMPO REAL
  // =====================================
  void fetchDatosUnidades() {
    _isLoading = true;
    notifyListeners();

    // Escuchamos la colección de Unidades
    _db.collection('unidades').snapshots().listen((snapshotUnidades) {
      _unidades = snapshotUnidades.docs
          .map((doc) => UnidadModel.fromJson(doc.data()))
          .toList();

      // Escuchamos la colección de Cargos
      _db.collection('cargos').snapshots().listen((snapshotCargos) {
        _todosLosCargos = snapshotCargos.docs
            .map((doc) => CargoUnidadModel.fromJson(doc.data()))
            .toList();

        _isLoading = false;
        notifyListeners();
      });
    });
  }

  // =====================================
  // 2. CREAR (CREATE)
  // =====================================
  Future<bool> addUnidad(String nombre, String abreviatura) async {
    try {
      int newId = DateTime.now().millisecondsSinceEpoch; // ID numérico único
      await _db.collection('unidades').doc(newId.toString()).set({
        'id': newId,
        'nombre': nombre.toUpperCase(),
        'abreviatura': abreviatura.toUpperCase(),
        'estado': true,
        'totalCargosProceso': 0,
      });
      return true;
    } catch (e) {
      print("Error al crear unidad: $e");
      return false;
    }
  }

  Future<bool> addCargo(String nombre, int unidadId, String tipo) async {
    try {
      int newId = DateTime.now().millisecondsSinceEpoch;
      await _db.collection('cargos').doc(newId.toString()).set({
        'id': newId,
        'nombre': nombre.toUpperCase(),
        'unidadId': unidadId,
        'activo': true,
        'tipo': tipo,
      });
      return true;
    } catch (e) {
      print("Error al crear cargo: $e");
      return false;
    }
  }

  // =====================================
  // 3. ACTUALIZAR (UPDATE)
  // =====================================
  Future<bool> updateUnidad(
    int id,
    String nuevoNombre,
    String nuevaAbreviatura,
  ) async {
    try {
      await _db.collection('unidades').doc(id.toString()).update({
        'nombre': nuevoNombre.toUpperCase(),
        'abreviatura': nuevaAbreviatura.toUpperCase(),
      });
      return true;
    } catch (e) {
      print("Error al actualizar unidad: $e");
      return false;
    }
  }

  Future<bool> updateCargo(int id, String nuevoNombre) async {
    try {
      await _db.collection('cargos').doc(id.toString()).update({
        'nombre': nuevoNombre.toUpperCase(),
      });
      return true;
    } catch (e) {
      print("Error al actualizar cargo: $e");
      return false;
    }
  }

  // Activar o desactivar un cargo/unidad (Soft Delete)
  Future<bool> toggleEstadoUnidad(int id, bool estadoActual) async {
    try {
      await _db.collection('unidades').doc(id.toString()).update({
        'estado': !estadoActual,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // =====================================
  // 4. ELIMINAR (DELETE FÍSICO)
  // =====================================
  Future<bool> deleteUnidad(int id) async {
    try {
      // Opcional: También podrías borrar los cargos que pertenezcan a esta unidad
      await _db.collection('unidades').doc(id.toString()).delete();
      return true;
    } catch (e) {
      print("Error al eliminar unidad: $e");
      return false;
    }
  }

  Future<bool> deleteCargo(int id) async {
    try {
      await _db.collection('cargos').doc(id.toString()).delete();
      return true;
    } catch (e) {
      print("Error al eliminar cargo: $e");
      return false;
    }
  }
}
