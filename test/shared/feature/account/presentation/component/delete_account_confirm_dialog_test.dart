import 'package:driver_app/l10n/app_localizations.dart';
import 'package:driver_app/shared/feature/account/presentation/component/delete_account_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prueba punta a punta de la infraestructura de i18n: que los delegates estén
/// bien cableados, que las keys del .arb resuelvan, y que la traducción al
/// inglés exista de verdad (no que caiga silenciosamente al español).
void main() {
  Widget harness(Locale locale) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: DeleteAccountConfirmDialog()),
    );
  }

  testWidgets('renders its copy in Spanish', (tester) async {
    await tester.pumpWidget(harness(const Locale('es')));

    // 'Eliminar cuenta' aparece dos veces a propósito: título y botón de
    // confirmar comparten la misma key (deleteAccountTitle).
    expect(find.text('Eliminar cuenta'), findsNWidgets(2));
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.textContaining('Esta acción es irreversible'), findsOneWidget);
    expect(find.textContaining('vehículo registrado'), findsOneWidget);
  });

  testWidgets('renders its copy in English', (tester) async {
    await tester.pumpWidget(harness(const Locale('en')));

    expect(find.text('Delete account'), findsNWidgets(2));
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.textContaining('This action is irreversible'),
      findsOneWidget,
    );
    expect(find.textContaining('registered vehicle'), findsOneWidget);
  });

  testWidgets('does not leak Spanish copy into the English locale', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const Locale('en')));

    expect(find.text('Eliminar cuenta'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
  });
}
