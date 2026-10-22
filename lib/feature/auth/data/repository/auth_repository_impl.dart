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

      if (!user.emailVerified) {
        // Reenvio best-effort: quien llega aqui suele haber perdido o dejado
        // vencer el correo original. Si falla (p. ej. too-many-requests) el
        // usuario igual ve el dialogo y puede reintentar mas tarde.
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('AuthDebug | No se pudo reenviar la verificacion: $e');
        }
        // Sin esto la sesion de Firebase queda abierta y SessionRepository la
        // tomaria como autenticada en el siguiente arranque.
        await auth.signOut();
        return left(Failure(code: FailureCode.emailNotVerified));
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

  @override
  Future<Either<Failure, Unit>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final FirebaseAuth auth = _firebaseAuth ?? FirebaseAuth.instance;
    try {
      final userCredentials = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredentials.user;
      if (user == null) {
        return left(Failure(code: FailureCode.signInFailed));
      }

      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint('AuthDebug | Error enviando verificacion en signUp: $e');
        await _signOutQuietly(auth: auth);
        return left(
          Failure(code: FailureCode.verificationEmailFailed, detail: '$e'),
        );
      }

      await _signOutQuietly(auth: auth);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthDebug | Error en signUpWithEmail: ${e.code}');
      return left(Failure(code: _signUpFailureCodeOf(code: e.code), detail: e.code));
    } catch (e) {
      debugPrint('AuthDebug | Error en signUpWithEmail: $e');
      return left(Failure(code: FailureCode.signInFailed, detail: '$e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      final FirebaseAuth auth = _firebaseAuth ?? FirebaseAuth.instance;
      await auth.sendPasswordResetEmail(email: email.trim());
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthDebug | Error en sendPasswordResetEmail: ${e.code}');
      // user-not-found se trata como exito: no se le revela a quien pregunta
      // si un correo tiene cuenta (y con la proteccion de enumeracion de
      // Firebase ni siquiera llega).
      if (e.code == 'user-not-found') return const Right(unit);
      return left(
        Failure(
          code: e.code == 'invalid-email'
              ? FailureCode.invalidEmail
              : FailureCode.passwordResetFailed,
          detail: e.code,
        ),
      );
    } catch (e) {
      debugPrint('AuthDebug | Error en sendPasswordResetEmail: $e');
      return left(Failure(code: FailureCode.passwordResetFailed, detail: '$e'));
    }
  }

  FailureCode _signUpFailureCodeOf({required String code}) {
    return switch (code) {
      'email-already-in-use' => FailureCode.emailAlreadyInUse,
      'weak-password' => FailureCode.weakPassword,
      'invalid-email' => FailureCode.invalidEmail,
      _ => FailureCode.signInFailed,
    };
  }

  Future<void> _signOutQuietly({required FirebaseAuth auth}) async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('AuthDebug | No se pudo cerrar la sesion tras signUp: $e');
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
