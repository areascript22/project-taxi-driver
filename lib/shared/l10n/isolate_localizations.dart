import 'dart:io';

import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Carga las traducciones SIN BuildContext, para código que corre fuera del
/// árbol de widgets.
///
/// Lo necesita el isolate del foreground service (ver
/// driver_foreground_service_entry_point.dart): ese isolate no tiene
/// MaterialApp ni BuildContext, así que `AppLocalizations.of(context)` no
/// existe ahí. En vez de dejar ese texto hablado hardcodeado en español, se
/// resuelve el locale del sistema y se carga el delegate a mano.
///
/// Ojo: usa el locale del SISTEMA, no el de la app. Si más adelante se agrega
/// un selector de idioma dentro de la app, el valor elegido habría que
/// persistirlo (SharedPreferences) y leerlo acá, porque el isolate no comparte
/// memoria con la UI.
Future<AppLocalizations> loadIsolateLocalizations() async {
  final systemCode = Platform.localeName.split(RegExp('[_-]')).first;
  final locale = AppLocalizations.supportedLocales.firstWhere(
    (supported) => supported.languageCode == systemCode,
    // El template del .arb es español: es el fallback natural.
    orElse: () => const Locale('es'),
  );
  return AppLocalizations.delegate.load(locale);
}
