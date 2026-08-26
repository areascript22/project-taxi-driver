import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../core/error/errors.dart';
import '../../../../domain/entity/user_entity.dart';
import '../../../../domain/repository/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  @override
  Future<Either<Failure, UserEntity>> isUserAuthenticated() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? currentUser = auth.currentUser;

      if (currentUser != null) {
        // Fuerza el refresh del ID token en cada arranque de la app para
        // que los custom claims (ej. rol admin) estén siempre al día,
        // incluso si cambiaron mientras la app estaba cerrada.
        try {
          await currentUser.getIdToken(true);
        } catch (e) {
          debugPrint('SessionDebug | No se pudo refrescar el ID token: $e');
        }

        return right(
          UserEntity(
            id: currentUser.uid,
            email: currentUser.email,
            displayName: currentUser.displayName,
            photoUrl: currentUser.photoURL,
          ),
        );
      }

      return Left(Failure(message: 'User is not signed in'));
    } catch (e) {
      return left(Failure(message: "Error interno al verificar la sesión: $e"));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      await auth.signOut();
      return const Right(unit);
    } catch (e) {
      return left(Failure(message: "Error al cerrar sesión: $e"));
    }
  }
}
