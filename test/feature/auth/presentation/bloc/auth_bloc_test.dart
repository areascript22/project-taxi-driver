import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';import 'package:driver_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:driver_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/shared/domain/entity/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  final user = UserEntity(
    id: 'uid-1',
    email: 'driver@example.com',
    displayName: 'Driver One',
    photoUrl: 'https://example.com/photo.png',
  );

  setUp(() {
    authRepository = MockAuthRepository();
  });

  AuthBloc buildBloc() => AuthBloc(authRepository: authRepository);

  test('initial state is AuthInitial', () {
    expect(buildBloc().state, isA<AuthInitial>());
  });

  group('AuthSignInWithGoogle', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when sign-in succeeds',
      setUp: () {
        when(
          () => authRepository.signInWithGoogle(),
        ).thenAnswer((_) async => Right(user));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AuthSignInWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', user),
      ],
      verify: (_) {
        verify(() => authRepository.signInWithGoogle()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when sign-in fails',
      setUp: () {
        when(() => authRepository.signInWithGoogle()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.unexpected)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AuthSignInWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.code, 'code', FailureCode.unexpected),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with empty message when failure has an empty message',
      setUp: () {
        when(
          () => authRepository.signInWithGoogle(),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AuthSignInWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.code, 'code', FailureCode.unexpected),
      ],
    );

  });

  group('AuthSignInWithEmail', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when sign-in succeeds',
      setUp: () {
        when(
          () => authRepository.signInWithEmail(
            email: 'driver@example.com',
            password: 'secret1',
          ),
        ).thenAnswer((_) async => Right(user));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AuthSignInWithEmail(email: 'driver@example.com', password: 'secret1'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', user),
      ],
      verify: (_) {
        verify(
          () => authRepository.signInWithEmail(
            email: 'driver@example.com',
            password: 'secret1',
          ),
        ).called(1);
        verifyNever(() => authRepository.signInWithGoogle());
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with the code when credentials are wrong',
      setUp: () {
        when(
          () => authRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.invalidCredentials)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AuthSignInWithEmail(email: 'driver@example.com', password: 'bad'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.code,
          'code',
          FailureCode.invalidCredentials,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthEmailNotVerified (not AuthError) when the email is unverified',
      setUp: () {
        when(
          () => authRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.emailNotVerified)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AuthSignInWithEmail(email: 'driver@example.com', password: 'secret1'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthEmailNotVerified>().having(
          (s) => s.email,
          'email',
          'driver@example.com',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'ignores a second attempt while one is in flight',
      setUp: () {
        when(
          () => authRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(user);
        });
      },
      build: buildBloc,
      act: (bloc) {
        bloc.add(AuthSignInWithEmail(email: 'a@b.co', password: 'x'));
        bloc.add(AuthSignInWithEmail(email: 'a@b.co', password: 'x'));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
      verify: (_) {
        verify(
          () => authRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).called(1);
      },
    );
  });

  group('AuthSignUpWithEmail', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSignUpCompleted] when the account is created',
      setUp: () {
        when(
          () => authRepository.signUpWithEmail(
            email: 'new@example.com',
            password: 'secret1',
          ),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AuthSignUpWithEmail(email: 'new@example.com', password: 'secret1'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSignUpCompleted>().having(
          (s) => s.email,
          'email',
          'new@example.com',
        ),
      ],
      verify: (_) {
        verify(
          () => authRepository.signUpWithEmail(
            email: 'new@example.com',
            password: 'secret1',
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with the code when sign-up fails',
      setUp: () {
        when(
          () => authRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.emailAlreadyInUse)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AuthSignUpWithEmail(email: 'a@b.co', password: 'secret1'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.code,
          'code',
          FailureCode.emailAlreadyInUse,
        ),
      ],
    );
  });

  group('AuthPasswordResetRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthPasswordResetSent] when the email is sent',
      setUp: () {
        when(
          () => authRepository.sendPasswordResetEmail(email: 'a@b.co'),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AuthPasswordResetRequested(email: 'a@b.co')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthPasswordResetSent>().having((s) => s.email, 'email', 'a@b.co'),
      ],
      verify: (_) {
        verify(
          () => authRepository.sendPasswordResetEmail(email: 'a@b.co'),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when sending fails',
      setUp: () {
        when(
          () => authRepository.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.passwordResetFailed)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AuthPasswordResetRequested(email: 'a@b.co')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.code,
          'code',
          FailureCode.passwordResetFailed,
        ),
      ],
    );
  });
}
