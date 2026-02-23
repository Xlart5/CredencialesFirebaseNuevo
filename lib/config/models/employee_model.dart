import 'package:flutter/material.dart';

class Employee {
  final int id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String carnetIdentidad;
  final String? correo;
  final String celular;
  final bool accesoComputo;
  final String estadoActual;
  final String cargo; // <-- VUELVE A SER TEXTO
  final String unidad; // <-- VUELVE A SER TEXTO
  final String photoUrl;
  final String qrUrl;
  final String Circu;

  Employee({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.carnetIdentidad,
    this.correo,
    required this.celular,
    required this.accesoComputo,
    required this.estadoActual,
    required this.cargo,
    required this.unidad,
    required this.photoUrl,
    required this.qrUrl,
    required this.Circu,
  });

  String get nombreCompleto =>
      "$nombre $apellidoPaterno $apellidoMaterno".trim();
  String get ci => carnetIdentidad;
  int get estado => estadoActual.toUpperCase() == "PERSONAL REGISTRADO" ? 0 : 1;

  // TU LÓGICA DE COLORES
  Color get colorEstado {
    final estadoUpper = estadoActual.toUpperCase();
    if (estadoUpper == "PERSONAL REGISTRADO") {
      return Colors.redAccent;
    } else if (estadoUpper.contains("RENUNCIA")) {
      return Colors.orangeAccent;
    } else {
      return Colors.greenAccent.shade700;
    }
  }

  // Nuevo constructor para leer desde Firebase Firestore
  factory Employee.fromFirestore(Map<String, dynamic> json, String documentId) {
    return Employee(
      // Ahora el ID principal es un número temporal, pero nos basamos en el CI
      id: int.tryParse(documentId) ?? 0,
      nombre: json['nombre'] ?? '',
      apellidoPaterno: json['apellidoPaterno'] ?? '',
      apellidoMaterno: json['apellidoMaterno'] ?? '',
      carnetIdentidad: json['ci'] ?? json['carnetIdentidad'] ?? documentId,
      correo: json['correo'] ?? 'sin correo',
      celular: json['celular'] ?? '',
      accesoComputo: json['accesoComputo'] ?? false,
      estadoActual: json['estadoActual'] ?? 'DESCONOCIDO',
      cargo: json['cargo'] ?? 'Sin Cargo',
      unidad: json['unidad'] ?? 'Sin Unidad',
      // Firebase Storage te guardó un enlace limpio, lo leemos directo
      photoUrl: json['photoUrl'] ?? '',
      qrUrl: json['qrUrl'] ?? '',
      Circu: json['nroCircunscripcion'] ?? '',
    );
  }

  Employee copyWith({
    int? id,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? carnetIdentidad,
    String? correo,
    String? celular,
    bool? accesoComputo,
    String? estadoActual,
    String? cargo,
    String? unidad,
    String? photoUrl,
    String? qrUrl,
    String? circuns,
  }) {
    return Employee(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      carnetIdentidad: carnetIdentidad ?? this.carnetIdentidad,
      correo: correo ?? this.correo,
      celular: celular ?? this.celular,
      accesoComputo: accesoComputo ?? this.accesoComputo,
      estadoActual: estadoActual ?? this.estadoActual,
      cargo: cargo ?? this.cargo,
      unidad: unidad ?? this.unidad,
      photoUrl: photoUrl ?? this.photoUrl,
      qrUrl: qrUrl ?? this.qrUrl,
      Circu: circuns ?? this.Circu,
    );
  }
}
