import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/auth/domain/repository/auth_repository.dart';
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
          (_) async => Left(Failure(message: 'Google sign-in cancelado')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AuthSignInWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          'Google sign-in cancelado',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with empty message when failure has an empty message',
      setUp: () {
        when(
          () => authRepository.signInWithGoogle(),
        ).thenAnswer((_) async => Left(Failure(message: '')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(AuthSignInWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.message, 'message', ''),
      ],
    );

  });
}
