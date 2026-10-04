import 'package:driver_app/core/l10n/app_language.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import 'package:driver_app/shared/feature/settings/domain/repository/settings_repository.dart';

/// Carga las traducciones SIN BuildContext, para código que corre fuera del
/// árbol de widgets.
///
/// Lo necesita el isolate del foreground service (ver
/// driver_foreground_service_entry_point.dart): ese isolate no tiene
/// MaterialApp ni BuildContext, así que `AppLocalizations.of(context)` no
/// existe ahí.
///
/// Respeta el idioma que el usuario eligió en Ajustes, no solo el del sistema:
/// la preferencia vive en SharedPreferences, que es el mismo almacenamiento
/// desde los dos isolates. Sin esto, elegir inglés en la app dejaría la alerta
/// hablada de "carrera nueva" en el idioma del teléfono.
Future<AppLocalizations> loadIsolateLocalizations({
  required SettingsRepository settingsRepository,
}) async {
  final result = await settingsRepository.getLanguage();
  final preference = result.fold((_) => AppLanguage.system, (value) => value);

  return AppLocalizations.delegate.load(
    resolveSystemAppLocale(preference: preference),
  );
}
