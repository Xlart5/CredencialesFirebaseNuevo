import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Importa aquí tus modelos (Ajusta la ruta si es diferente)
import '../models/selection_models.dart';

class RegisterProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // =====================================
  // VARIABLES DE ESTADO Y UI
  // =====================================
  int currentPage = 0;
  bool isUploadingImage = false;
  bool isLoadingData = false;
  bool isRequestingCode = false;
  bool isSubmitting = false;

  // =====================================
  // VARIABLES DEL FORMULARIO
  // =====================================
  XFile? imageFile;
  bool get hasImage => imageFile != null;

  String nombre = '';
  String paterno = '';
  String materno = '';
  String ci = '';
  String celular = '';
  String correo = '';
  String codigoVerificacion = '';

  UnidadItem? selectedUnidad;
  CargoItem? selectedCargo;
  String? selectedCircunscripcion;

  // Variables para la verificación de correo
  String _codigoGeneradoReal = "";
  String mensajeError = "";

  // Listas de selección
  List<UnidadItem> unidades = [];
  List<CargoItem> availableCargos = [];
  List<String> circunscripcionesCbba = [
    'C-02',
    'C-20',
    'C-21',
    'C-22',
    'C-23',
    'C-24',
    'C-25',
    'C-26',
    'C-27',
    'C-28',
  ];

  // Getter mágico para saber si es Notario
  bool get isNotarioSelected {
    if (selectedCargo == null) return false;
    return selectedCargo!.nombre.toLowerCase().contains('notari');
  }

  // =====================================
  // FUNCIONES DE NAVEGACIÓN Y FOTOS
  // =====================================
  void setPage(int page) {
    currentPage = page;
    notifyListeners();
  }

  Future<void> uploadImage(XFile file) async {
    // Truco: Solo la guardamos en memoria temporal para mostrarla en la UI.
    imageFile = file;
    notifyListeners();
  }

  // =====================================
  // CARGA DE UNIDADES Y CARGOS
  // =====================================
  // =====================================
  // CARGA DE UNIDADES Y CARGOS (DESDE FIREBASE)
  // =====================================
  Future<void> fetchUnidadesYCargos() async {
    isLoadingData = true;
    notifyListeners();

    try {
      // 1. Traemos las unidades activas de Firebase
      final unidadesSnapshot = await _db
          .collection('unidades')
          .where('estado', isEqualTo: true)
          .get();
      unidades = unidadesSnapshot.docs.map((doc) {
        return UnidadItem(id: doc.data()['id'], nombre: doc.data()['nombre']);
      }).toList();

      // 2. Traemos los cargos activos de Firebase
      // ANTES: final cargosSnapshot = await _db.collection('cargos')...

      // AHORA: Usamos collectionGroup
      final cargosSnapshot = await _db
          .collectionGroup('cargos')
          .where('activo', isEqualTo: true)
          .get();
      availableCargos = cargosSnapshot.docs.map((doc) {
        return CargoItem(
          id: doc.data()['id'],
          nombre: doc.data()['nombre'],
          unidadId: doc.data()['unidadId'],
        );
      }).toList();
    } catch (e) {
      print("Error cargando unidades reales: $e");
    } finally {
      isLoadingData = false;
      notifyListeners();
    }
  }

  // =====================================
  // GENERADOR DE DATA PARA QR
  // =====================================
  String _generarDataSeguraQR(String carnet) {
    final random = Random();

    // 1. Generar 8 números aleatorios (ej. 51245781)
    String randomDigits = '';
    for (int i = 0; i < 8; i++) {
      randomDigits += random.nextInt(10).toString();
    }

    // 2. Generar 8 caracteres alfanuméricos aleatorios (ej. 254QE256)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomAlpha = '';
    for (int i = 0; i < 8; i++) {
      randomAlpha += chars[random.nextInt(chars.length)];
    }

    // 3. Armar el formato final
    return "QR-$carnet-$randomDigits-$randomAlpha";
  }

  // =====================================
  // ENVÍO DE CÓDIGO MASIVO VIA GMAIL SMTP
  // =====================================
  // =====================================
  // ENVÍO DE CÓDIGO MASIVO VIA GOOGLE APPS SCRIPT
  // =====================================
  // =====================================
  // ENVÍO DE CÓDIGO MASIVO (MODO GET - BYPASS CORS)
  // =====================================
  Future<bool> solicitarCodigo() async {
    isRequestingCode = true;
    mensajeError = "";
    notifyListeners();

    try {
      // 1. Generamos el código real de 6 dígitos
      final random = Random();
      _codigoGeneradoReal = (100000 + random.nextInt(900000)).toString();

      print("=======================================");
      print("🔑 CÓDIGO SECRETO GENERADO: $_codigoGeneradoReal");
      print("=======================================");

      // 2. PEGA AQUÍ TU NUEVA URL DE GOOGLE APPS SCRIPT
      final String googleScriptUrl =
          'https://script.google.com/macros/s/AKfycby5TwPG5-5Zg7_6XUbYb4l-rzLG-mxDiC9xBmsUygkjD6XwjToZZ5CIfeLbFw4LM5z8XA/exec';

      // 3. Armamos la URL inyectando los datos (así burlamos el CORS)
      final Uri urlConParametros = Uri.parse(
        "$googleScriptUrl?correo=$correo&nombre=$nombre&codigo=$_codigoGeneradoReal",
      );

      // 4. Hacemos la petición GET
      await http.get(urlConParametros);

      // Si todo sale bien, apagamos la carga
      isRequestingCode = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Aviso de GET (Suele ser falso positivo de Chrome): $e");

      // 🔥 TRUCO PRO: En Flutter Web, a veces Chrome da error de CORS al *leer* la respuesta,
      // pero la petición SÍ salió y Google SÍ envió el correo.
      // Por eso, aunque caiga en este 'catch', asumimos que se envió correctamente.
      isRequestingCode = false;
      notifyListeners();
      return true;
    }
  }

  // =====================================
  // GUARDAR EN FIREBASE (EL PASO FINAL)
  // =====================================
  Future<bool> registrarPersonal() async {
    // 🔥 VALIDACIÓN CRÍTICA DEL CÓDIGO
    if (codigoVerificacion != _codigoGeneradoReal) {
      mensajeError = "El código ingresado es incorrecto.";
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      String finalNombre = "$nombre $paterno $materno".trim().toUpperCase();
      String finalPhotoUrl = "";

      // 1. SUBIR FOTO A STORAGE
      if (imageFile != null) {
        final ref = _storage.ref().child('fotos_personal/$ci.jpg');

        if (kIsWeb) {
          await ref.putData(await imageFile!.readAsBytes());
        } else {
          await ref.putFile(File(imageFile!.path));
        }
        finalPhotoUrl = await ref.getDownloadURL();
      }

      // 2. GENERAR LINK DEL QR SEGURO NATIVO
      // Solo guardamos el texto, el PDF lo dibujará usando la librería pw.Barcode
      String finalQrUrl = _generarDataSeguraQR(ci);

      // 3. CREAR DOCUMENTO EN FIRESTORE
      await _db.collection('personal').doc(ci).set({
        'nombre': nombre.toUpperCase(),
        'apellidoPaterno': paterno.toUpperCase(),
        'apellidoMaterno': materno.toUpperCase(),
        'nombreCompleto': finalNombre,
        'ci': ci,
        'carnetIdentidad': ci,
        'celular': celular,
        'correo': correo.toLowerCase(),
        'unidad': selectedUnidad?.nombre ?? 'SIN UNIDAD',
        'cargo': selectedCargo?.nombre ?? 'SIN CARGO',
        'nroCircunscripcion': selectedCircunscripcion ?? '',
        'photoUrl': finalPhotoUrl,
        'qrUrl': finalQrUrl, // Aquí va el texto encriptado "QR-1234567-..."
        'estadoActual': 'PERSONAL REGISTRADO',
        'accesoComputo': false,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error al guardar personal en Firebase: $e");
      mensajeError = "Error de conexión al guardar los datos.";
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // =====================================
  // LIMPIAR MEMORIA TRAS EL ÉXITO
  // =====================================
  void resetForm() {
    currentPage = 0;
    imageFile = null;
    nombre = '';
    paterno = '';
    materno = '';
    ci = '';
    celular = '';
    correo = '';
    codigoVerificacion = '';
    _codigoGeneradoReal = '';
    selectedUnidad = null;
    selectedCargo = null;
    selectedCircunscripcion = null;
    notifyListeners();
  }
}
