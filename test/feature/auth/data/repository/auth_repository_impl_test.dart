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
      when(() => user.emailVerified).thenReturn(true);
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

    MockUser unverifiedUser() {
      final user = MockUser();
      when(() => user.emailVerified).thenReturn(false);
      when(() => user.sendEmailVerification()).thenAnswer((_) async {});
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      stubSignIn(() async => credential);
      when(() => auth.signOut()).thenAnswer((_) async {});
      return user;
    }

    test('blocks an unverified email: emailNotVerified, resend and sign out',
        () async {
      final user = unverifiedUser();

      final result = await repository.signInWithEmail(
        email: 'a@b.co',
        password: 'x',
      );

      expect(
        result.swap().getOrElse(() => throw StateError('expected Left')).code,
        FailureCode.emailNotVerified,
      );
      verify(() => user.sendEmailVerification()).called(1);
      verify(() => auth.signOut()).called(1);
    });

    test('still blocks and signs out when the resend fails', () async {
      final user = unverifiedUser();
      when(() => user.sendEmailVerification())
          .thenThrow(FirebaseAuthException(code: 'too-many-requests'));

      final result = await repository.signInWithEmail(
        email: 'a@b.co',
        password: 'x',
      );

      expect(
        result.swap().getOrElse(() => throw StateError('expected Left')).code,
        FailureCode.emailNotVerified,
      );
      verify(() => auth.signOut()).called(1);
    });
  });

  group('signUpWithEmail', () {
    MockUser stubCreate({Future<void> Function()? verification}) {
      final user = MockUser();
      when(() => user.sendEmailVerification())
          .thenAnswer((_) => (verification ?? () async {})());
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);
      when(() => auth.signOut()).thenAnswer((_) async {});
      return user;
    }

    test('creates the account, sends verification and signs out', () async {
      final user = stubCreate();

      final result = await repository.signUpWithEmail(
        email: ' new@example.com ',
        password: 'secret1',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => auth.createUserWithEmailAndPassword(
          email: 'new@example.com',
          password: 'secret1',
        ),
      ).called(1);
      verify(() => user.sendEmailVerification()).called(1);
      verify(() => auth.signOut()).called(1);
    });

    test('returns verificationEmailFailed (and signs out) if the email fails',
        () async {
      stubCreate(
        verification: () async => throw FirebaseAuthException(code: 'x'),
      );

      final result = await repository.signUpWithEmail(
        email: 'new@example.com',
        password: 'secret1',
      );

      expect(
        result.swap().getOrElse(() => throw StateError('expected Left')).code,
        FailureCode.verificationEmailFailed,
      );
      verify(() => auth.signOut()).called(1);
    });

    final cases = {
      'email-already-in-use': FailureCode.emailAlreadyInUse,
      'weak-password': FailureCode.weakPassword,
      'invalid-email': FailureCode.invalidEmail,
      'network-request-failed': FailureCode.signInFailed,
    };
    cases.forEach((code, expected) {
      test('maps FirebaseAuthException($code) to $expected', () async {
        when(
          () => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: code));

        final result = await repository.signUpWithEmail(
          email: 'a@b.co',
          password: 'secret1',
        );

        expect(
          result.swap().getOrElse(() => throw StateError('expected Left')).code,
          expected,
        );
        verifyNever(() => auth.signOut());
      });
    });
  });

  group('sendPasswordResetEmail', () {
    test('sends the reset email with the trimmed address', () async {
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      final result =
          await repository.sendPasswordResetEmail(email: ' a@b.co ');

      expect(result.isRight(), isTrue);
      verify(() => auth.sendPasswordResetEmail(email: 'a@b.co')).called(1);
    });

    test('treats user-not-found as success (does not reveal accounts)',
        () async {
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final result = await repository.sendPasswordResetEmail(email: 'a@b.co');

      expect(result.isRight(), isTrue);
    });

    test('maps invalid-email to invalidEmail', () async {
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));

      final result = await repository.sendPasswordResetEmail(email: 'bad');

      expect(
        result.swap().getOrElse(() => throw StateError('expected Left')).code,
        FailureCode.invalidEmail,
      );
    });

    test('maps any other failure to passwordResetFailed', () async {
      when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final result = await repository.sendPasswordResetEmail(email: 'a@b.co');

      expect(
        result.swap().getOrElse(() => throw StateError('expected Left')).code,
        FailureCode.passwordResetFailed,
      );
    });
  });
}
