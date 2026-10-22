import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../../../../shared/domain/entity/user_entity.dart';

abstract class AuthRepository{
  Future<Either<Failure, UserEntity >> signInWithGoogle();

  /// Solo deja pasar a quien ya verificó su correo: si no, cierra la sesión que
  /// Firebase acaba de abrir y devuelve [FailureCode.emailNotVerified].
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Crea la cuenta, envía el correo de verificación y cierra la sesión: la
  /// cuenta no puede usarse hasta que el correo esté confirmado.
  Future<Either<Failure, Unit>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> sendPasswordResetEmail({required String email});
}