/// Minimo que exige Firebase Auth para una contrasena de correo/contrasena.
const int minPasswordLength = 6;

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Validacion de formato solo para dar feedback inmediato en el formulario;
/// la que manda es la de Firebase Auth (`invalid-email`).
bool isEmailFormatValid({required String email}) {
  return _emailPattern.hasMatch(email.trim());
}
