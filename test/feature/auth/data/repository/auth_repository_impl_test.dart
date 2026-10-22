import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth auth;
  late AuthRepositoryImpl repository;

  setUp(() {
    auth = MockFirebaseAuth();
    repository = AuthRepositoryImpl(firebaseAuth: auth);
  });

  void stubSignIn(Future<UserCredential> Function() answer) {
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  group('signInWithEmail', () {
    test('returns the user entity and trims the email on success', () async {
      final user = MockUser();
      when(() => user.uid).thenReturn('uid-1');
      when(() => user.email).thenReturn('driver@example.com');
      when(() => user.displayName).thenReturn(null);
      when(() => user.photoURL).thenReturn(null);
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      stubSignIn(() async => credential);

      final result = await repository.signInWithEmail(
        email: '  driver@example.com ',
        password: 'secret1',
      );

      final entity = result.getOrElse(() => throw StateError('expected Right'));
      expect(entity.id, 'uid-1');
      expect(entity.email, 'driver@example.com');
      expect(entity.displayName, isNull);
      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'driver@example.com',
          password: 'secret1',
        ),
      ).called(1);
    });

    test('returns signInFailed when Firebase gives no user', () async {
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(null);
      stubSignIn(() async => credential);

      final result = await repository.signInWithEmail(
        email: 'a@b.co',
        password: 'x',
      );

      expect(result.swap().getOrElse(() => throw StateError('expected Left')).code,
          FailureCode.signInFailed);
    });

    for (final code in [
      'invalid-credential',
      'wrong-password',
      'user-not-found',
      'invalid-email',
    ]) {
      test('maps FirebaseAuthException($code) to invalidCredentials', () async {
        stubSignIn(() async => throw FirebaseAuthException(code: code));

        final result = await repository.signInWithEmail(
          email: 'a@b.co',
          password: 'x',
        );

        final failure =
            result.swap().getOrElse(() => throw StateError('expected Left'));
        expect(failure.code, FailureCode.invalidCredentials);
        expect(failure.detail, code);
      });
    }

    for (final code in ['network-request-failed', 'too-many-requests', 'user-disabled']) {
      test('maps FirebaseAuthException($code) to signInFailed', () async {
        stubSignIn(() async => throw FirebaseAuthException(code: code));

        final result = await repository.signInWithEmail(
          email: 'a@b.co',
          password: 'x',
        );

        expect(
          result.swap().getOrElse(() => throw StateError('expected Left')).code,
          FailureCode.signInFailed,
        );
      });
    }

    test('maps any other exception to signInFailed', () async {
      stubSignIn(() async => throw Exception('boom'));

      final result = await repository.signInWithEmail(
        email: 'a@b.co',
        password: 'x',
      );

      expect(
        result.swap().getOrElse(() => throw StateError('expected Left')).code,
        FailureCode.signInFailed,
      );
    });
  });
}
