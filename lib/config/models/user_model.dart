class UserModel {
  final String uid; // El ID único que le da Firebase
  final String email;
  final String nombreCompleto;
  final String rol;

  UserModel({
    required this.uid,
    required this.email,
    required this.nombreCompleto,
    required this.rol,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
    String uid,
    String email,
  ) {
    return UserModel(
      uid: uid,
      email: email,
      nombreCompleto: json['nombreCompleto'] ?? 'Administrador',
      rol: json['rol'] ?? 'ADMIN',
    );
  }
}
