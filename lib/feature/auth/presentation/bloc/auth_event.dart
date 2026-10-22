part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class AuthSignInWithGoogle extends AuthEvent {}

class AuthSignUpWithEmail extends AuthEvent {
  final String email;
  final String password;

  AuthSignUpWithEmail({required this.email, required this.password});
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  AuthPasswordResetRequested({required this.email});
}

class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  AuthSignInWithEmail({required this.email, required this.password});
}

