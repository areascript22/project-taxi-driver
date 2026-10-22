import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/error/errors.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth;

  // Opcional para poder inyectar un mock en los tests; en la app se usa la
  // instancia global (resuelta de forma perezosa, tras Firebase.initializeApp).
  final FirebaseAuth? _firebaseAuth;

  // Codigos de FirebaseAuthException que significan "esas credenciales no
  // sirven". Firebase unifica casi todo en invalid-credential (proteccion de
  // enumeracion de correos); los otros dos quedan por proyectos antiguos.
  static const _invalidCredentialCodes = {
    'invalid-credential',
    'wrong-password',
    'user-not-found',
    'invalid-email',
  };

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final FirebaseAuth auth = _firebaseAuth ?? FirebaseAuth.instance;
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredentials = await auth.signInWithCredential(credential);
      final user = userCredentials.user;

      if (user != null) {
        return right(_toEntity(user));
      } else {
        return left(
          Failure(code: FailureCode.signInFailed),
        );
      }
    } catch (e) {
      return left(Failure(code: FailureCode.signInFailed));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final FirebaseAuth auth = _firebaseAuth ?? FirebaseAuth.instance;
      final userCredentials = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredentials.user;

      if (user == null) {
        return left(Failure(code: FailureCode.signInFailed));
      }
      return right(_toEntity(user));
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthDebug | Error en signInWithEmail: ${e.code}');
      return left(
        Failure(
          code: _invalidCredentialCodes.contains(e.code)
              ? FailureCode.invalidCredentials
              : FailureCode.signInFailed,
          detail: e.code,
        ),
      );
    } catch (e) {
      debugPrint('AuthDebug | Error en signInWithEmail: $e');
      return left(Failure(code: FailureCode.signInFailed, detail: '$e'));
    }
  }

  UserEntity _toEntity(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
