import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Firebase maneja el estado internamente, pero mantenemos tu variable para compatibilidad
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password, bool recordar) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Iniciamos sesión directamente con los servidores de Google/Firebase
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 2. Opcional: Si quieres traer el "Rol" y "Nombre" de la base de datos (Firestore)
      // Buscamos un documento en la colección 'usuarios' que tenga el mismo ID que este login
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credential.user!.uid)
          .get();

      Map<String, dynamic> extraData = {};
      if (userDoc.exists) {
        extraData = userDoc.data() as Map<String, dynamic>;
      }

      // 3. Llenamos nuestro modelo
      _currentUser = UserModel.fromJson(
        extraData,
        credential.user!.uid,
        credential.user!.email ?? '',
      );

      // Si el usuario marcó "recordar", Firebase lo hace automáticamente por defecto en Web.
      // Así que no necesitas programar SharedPreferences manual para la sesión.

      _isLoading = false;
      notifyListeners();
      return true; // Login exitoso
    } on FirebaseAuthException catch (e) {
      // 4. Traducimos los errores de Firebase al español
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        _errorMessage = 'No se encontró un usuario con ese correo.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = 'Contraseña incorrecta.';
      } else {
        _errorMessage = 'Error de autenticación: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
