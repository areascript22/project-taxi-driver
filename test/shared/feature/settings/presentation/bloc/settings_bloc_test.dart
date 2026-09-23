import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/shared/feature/settings/domain/repository/settings_repository.dart';
import 'package:driver_app/shared/feature/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    repository = MockSettingsRepository();
    when(
      () => repository.setThemeMode(any()),
    ).thenAnswer((_) async => Right(unit));
    when(
      () => repository.setVoiceEnabled(any()),
    ).thenAnswer((_) async => Right(unit));
    when(
      () => repository.setVibrationEnabled(any()),
    ).thenAnswer((_) async => Right(unit));
  });

  SettingsBloc buildBloc() => SettingsBloc(repository: repository);

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
          (_) async => Left(Failure(message: 'err')),
        );
        when(() => repository.isVibrationEnabled()).thenAnswer(
          (_) async => Left(Failure(message: 'err')),
        );
        when(() => repository.getThemeMode()).thenAnswer(
          (_) async => Left(Failure(message: 'err')),
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
}
