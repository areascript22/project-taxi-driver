import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/incoming_request/presentation/component/location_issue_banner.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// El aviso que le dice al conductor POR QUE no recibe pedidos cuando no hay
// ubicacion utilizable.
void main() {
  Widget host({
    required FailureCode issue,
    required VoidCallback onTap,
    Locale locale = const Locale('es'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LocationIssueBanner(issue: issue, onOpenSettingsTapped: onTap),
      ),
    );
  }

  testWidgets('says the driver is not receiving rides and explains the reason', (tester) async {
    await tester.pumpWidget(host(issue: FailureCode.gpsDisabled, onTap: () {}));

    expect(find.text('No estás recibiendo pedidos'), findsOneWidget);
    expect(find.textContaining('alta precisión'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsOneWidget);
  });

  testWidgets('shows a different, specific reason for each cause', (tester) async {
    await tester.pumpWidget(host(issue: FailureCode.locationPermissionDenied, onTap: () {}));
    expect(find.textContaining('permiso de ubicación'), findsOneWidget);

    await tester.pumpWidget(host(issue: FailureCode.locationUnavailable, onTap: () {}));
    expect(find.textContaining('No logramos obtener tu ubicación'), findsOneWidget);
  });

  testWidgets('the settings button calls back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(issue: FailureCode.gpsDisabled, onTap: () => taps++));

    await tester.tap(find.text('Abrir ajustes'));

    expect(taps, 1);
  });

  testWidgets('is translated: English follows the same structure', (tester) async {
    await tester.pumpWidget(
      host(issue: FailureCode.gpsDisabled, onTap: () {}, locale: const Locale('en')),
    );

    expect(find.text("You're not receiving rides"), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.textContaining('high accuracy'), findsOneWidget);
  });
}
