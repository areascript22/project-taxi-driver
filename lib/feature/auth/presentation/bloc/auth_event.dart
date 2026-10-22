part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class AuthSignInWithGoogle extends AuthEvent {}

class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  AuthSignInWithEmail({required this.email, required this.password});
}

