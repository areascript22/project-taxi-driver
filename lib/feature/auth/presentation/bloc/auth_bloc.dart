import 'package:bloc/bloc.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:flutter/material.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../domain/repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInWithEmail>(_onSignInWithEmail);
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    // Evita un segundo intento mientras hay uno en curso (doble tap).
    if (state is AuthLoading) return;
    emit(AuthLoading());

    final result = await authRepository.signInWithEmail(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await authRepository.signInWithGoogle();

    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
}
