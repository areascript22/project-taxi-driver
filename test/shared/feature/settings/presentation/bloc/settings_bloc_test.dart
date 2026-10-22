import 'package:driver_app/core/l10n/app_language.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/driver_profile/domain/repository/driver_profile_repository.dart';
import 'package:driver_app/shared/domain/entity/user_entity.dart';
import 'package:driver_app/shared/domain/repository/session_repository.dart';
import 'package:driver_app/shared/feature/settings/domain/repository/settings_repository.dart';
import 'package:driver_app/shared/feature/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSettingsRepository repository;
  late MockDriverProfileRepository profileRepository;
  late MockSessionRepository sessionRepository;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
    registerFallbackValue(AppLanguage.system);
  });

  setUp(() {
    repository = MockSettingsRepository();
    profileRepository = MockDriverProfileRepository();
    sessionRepository = MockSessionRepository();
    when(() => sessionRepository.isUserAuthenticated()).thenAnswer(
      (_) async => Right(UserEntity(id: 'u1', email: 'j@example.com')),
    );
    when(
      () => profileRepository.updateLanguage(
        driverId: any(named: 'driverId'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => Right(unit));
    when(
      () => repository.setThemeMode(any()),
    ).thenAnswer((_) async => Right(unit));
    when(
      () => repository.setVoiceEnabled(any()),
    ).thenAnswer((_) async => Right(unit));
    when(
      () => repository.setVibrationEnabled(any()),
    ).thenAnswer((_) async => Right(unit));
    when(
      () => repository.setLanguage(any()),
    ).thenAnswer((_) async => Right(unit));
    // Default para los tests que no se ocupan del idioma: sin esto mocktail
    // tira "no stub" en LoadSettings, que ahora tambien lee el idioma.
    when(
      () => repository.getLanguage(),
    ).thenAnswer((_) async => Right(AppLanguage.system));
  });

  SettingsBloc buildBloc() => SettingsBloc(
    repository: repository,
    profileRepository: profileRepository,
    sessionRepository: sessionRepository,
  );

  test('initial state defaults to loading=true with system theme', () {
    final state = buildBloc().state;
    expect(state.isLoading, isTrue);
    expect(state.voiceEnabled, isTrue);
    expect(state.vibrationEnabled, isTrue);
    expect(state.themeMode, ThemeMode.system);
  });

  group('LoadSettings', () {
    blocTest<SettingsBloc, SettingsState>(
      'loads all preferences from the repository',
      setUp: () {
        when(() => repository.isVoiceEnabled()).thenAnswer((_) async => const Right(false));
        when(() => repository.isVibrationEnabled()).thenAnswer((_) async => const Right(false));
        when(() => repository.getThemeMode()).thenAnswer((_) async => Right(ThemeMode.dark));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSettings()),
      expect: () => [
        predicate<SettingsState>((s) => s.isLoading),
        predicate<SettingsState>(
          (s) =>
              !s.isLoading &&
              !s.voiceEnabled &&
              !s.vibrationEnabled &&
              s.themeMode == ThemeMode.dark,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'falls back to safe defaults (true/true/system) when every read fails',
      setUp: () {
        when(() => repository.isVoiceEnabled()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.unexpected)),
        );
        when(() => repository.isVibrationEnabled()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.unexpected)),
        );
        when(() => repository.getThemeMode()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.unexpected)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSettings()),
      expect: () => [
        predicate<SettingsState>((s) => s.isLoading),
        predicate<SettingsState>(
          (s) =>
              !s.isLoading &&
              s.voiceEnabled &&
              s.vibrationEnabled &&
              s.themeMode == ThemeMode.system,
        ),
      ],
    );
  });

  group('ToggleVoice', () {
    blocTest<SettingsBloc, SettingsState>(
      'flips voiceEnabled from true to false and persists it',
      build: buildBloc,
      act: (bloc) => bloc.add(ToggleVoice()),
      expect: () => [predicate<SettingsState>((s) => !s.voiceEnabled)],
      verify: (_) {
        verify(() => repository.setVoiceEnabled(false)).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'flips voiceEnabled from false back to true',
      build: buildBloc,
      seed: () => const SettingsState(voiceEnabled: false),
      act: (bloc) => bloc.add(ToggleVoice()),
      expect: () => [predicate<SettingsState>((s) => s.voiceEnabled)],
      verify: (_) {
        verify(() => repository.setVoiceEnabled(true)).called(1);
      },
    );
  });

  group('ToggleVibration', () {
    blocTest<SettingsBloc, SettingsState>(
      'flips vibrationEnabled and persists it',
      build: buildBloc,
      act: (bloc) => bloc.add(ToggleVibration()),
      expect: () => [predicate<SettingsState>((s) => !s.vibrationEnabled)],
      verify: (_) {
        verify(() => repository.setVibrationEnabled(false)).called(1);
      },
    );
  });

  group('ChangeThemeMode', () {
    blocTest<SettingsBloc, SettingsState>(
      'updates themeMode and persists it',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeThemeMode(ThemeMode.light)),
      expect: () => [
        predicate<SettingsState>((s) => s.themeMode == ThemeMode.light),
      ],
      verify: (_) {
        verify(() => repository.setThemeMode(ThemeMode.light)).called(1);
      },
    );
  });

  group('ChangeLanguage', () {
    blocTest<SettingsBloc, SettingsState>(
      'emite el idioma nuevo y lo persiste',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeLanguage(AppLanguage.english)),
      expect:
          () => [
            predicate<SettingsState>((s) => s.language == AppLanguage.english),
          ],
      verify: (_) {
        verify(() => repository.setLanguage(AppLanguage.english)).called(1);
      },
    );

    // El estado se emite ANTES de esperar al disco (igual que el tema): la UI
    // responde al toque al instante y no se queda trabada si la escritura
    // tarda o falla.
    blocTest<SettingsBloc, SettingsState>(
      'emite el idioma incluso si la escritura falla',
      setUp: () {
        when(
          () => repository.setLanguage(any()),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeLanguage(AppLanguage.spanish)),
      expect:
          () => [
            predicate<SettingsState>((s) => s.language == AppLanguage.spanish),
          ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'volver a system es una eleccion valida, no un no-op',
      build: buildBloc,
      seed: () => const SettingsState(language: AppLanguage.english),
      act: (bloc) => bloc.add(ChangeLanguage(AppLanguage.system)),
      expect:
          () => [
            predicate<SettingsState>((s) => s.language == AppLanguage.system),
          ],
      verify: (_) {
        verify(() => repository.setLanguage(AppLanguage.system)).called(1);
      },
    );

    // El copy de los push lo arma el backend, así que el idioma tiene que
    // llegar al documento del conductor en el acto: esperar al próximo
    // arranque dejaría las notificaciones en el idioma viejo justo después de
    // que el usuario pidiera lo contrario.
    blocTest<SettingsBloc, SettingsState>(
      'avisa el idioma nuevo al backend para los push',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeLanguage(AppLanguage.english)),
      verify: (_) {
        verify(
          () => profileRepository.updateLanguage(driverId: 'u1', language: 'en'),
        ).called(1);
      },
    );

    // Sin sesión no hay documento donde escribir. No debe ser un error ni
    // reventar: lo arregla el próximo login, que registra token e idioma.
    blocTest<SettingsBloc, SettingsState>(
      'no intenta avisarle al backend si no hay sesion',
      setUp: () {
        when(() => sessionRepository.isUserAuthenticated()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.notSignedIn)),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeLanguage(AppLanguage.english)),
      expect:
          () => [
            predicate<SettingsState>((s) => s.language == AppLanguage.english),
          ],
      verify: (_) {
        verifyNever(
          () => profileRepository.updateLanguage(
            driverId: any(named: 'driverId'),
            language: any(named: 'language'),
          ),
        );
      },
    );

    // 'system' es una preferencia válida en la app, pero el server no sabe
    // resolverla: lo que se guarda tiene que ser siempre un idioma concreto.
    blocTest<SettingsBloc, SettingsState>(
      'nunca le manda "system" al backend',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeLanguage(AppLanguage.system)),
      verify: (_) {
        final language =
            verify(
                  () => profileRepository.updateLanguage(
                    driverId: 'u1',
                    language: captureAny(named: 'language'),
                  ),
                ).captured.single
                as String;

        expect(language, isIn(const ['es', 'en']));
      },
    );
  });
}
