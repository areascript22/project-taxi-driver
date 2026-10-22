part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final UserEntity user;

  AuthAuthenticated({required this.user});
}

/// El correo todavia no se verifico: la UI muestra el dialogo de verificacion
/// en vez de un error. Lleva el correo para poder nombrarlo en el dialogo.
final class AuthEmailNotVerified extends AuthState {
  final String email;

  AuthEmailNotVerified({required this.email});
}

/// Cuenta creada y correo de verificacion enviado (sin sesion abierta).
final class AuthSignUpCompleted extends AuthState {
  final String email;

  AuthSignUpCompleted({required this.email});
}

final class AuthPasswordResetSent extends AuthState {
  final String email;

  AuthPasswordResetSent({required this.email});
}

final class AuthError extends AuthState {
  // Lleva el codigo, no el texto: el texto lo resuelve la pantalla con
  // context.failureText(code) -- ver core/error/errors.dart.
  final FailureCode code;

  AuthError(this.code);
}