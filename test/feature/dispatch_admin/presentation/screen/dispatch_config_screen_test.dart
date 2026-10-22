import 'package:dartz/dartz.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_config_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_limits_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_ring_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/repository/dispatch_admin_repository.dart';
import 'package:driver_app/feature/dispatch_admin/presentation/bloc/dispatch_config_bloc.dart';
import 'package:driver_app/feature/dispatch_admin/presentation/screen/dispatch_config_screen.dart';
import 'package:driver_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toastification/toastification.dart';

class MockDispatchAdminRepository extends Mock
    implements DispatchAdminRepository {}

const _limits = DispatchLimitsEntity(
  maxRings: 6,
  maxTotalWaitSeconds: 120,
  minLocationMaxAgeSeconds: 30,
  maxLocationMaxAgeSeconds: 600,
  minRadiusMeters: 100,
  maxRadiusMeters: 50000,
  minWaitSeconds: 1,
  maxWaitSeconds: 120,
  minMaxDrivers: 1,
  maxMaxDrivers: 100,
);

DispatchConfigEntity _config({
  bool canEdit = true,
  bool canChangeAdminEditing = true,
  bool adminsCanEdit = false,
}) => DispatchConfigEntity(
  rings: const [
    DispatchRingEntity(radiusMeters: 3000, waitSeconds: 10, maxDrivers: 10),
    DispatchRingEntity(radiusMeters: 6000, waitSeconds: 10, maxDrivers: 10),
  ],
  locationMaxAgeSeconds: 45,
  adminsCanEdit: adminsCanEdit,
  version: 0,
  updatedAt: null,
  updatedByName: '',
  totalWaitSeconds: 20,
  requestExpirySeconds: 35,
  canEdit: canEdit,
  canChangeAdminEditing: canChangeAdminEditing,
  limits: _limits,
);

// La pantalla de configuración del despacho según QUIÉN la abre: el superuser
// edita y ve el interruptor; un admin sin permiso solo mira; un admin con el
// interruptor encendido edita pero no lo ve.
void main() {
  late MockDispatchAdminRepository repository;

  setUp(() {
    repository = MockDispatchAdminRepository();
  });

  tearDown(() => toastification.dismissAll(delayForAnimation: false));

  // Un toast deja un temporizador de 3-4 s: hay que dejarlo correr y cerrar
  // antes de que termine el test.
  Future<void> letToastsFinish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, DispatchConfigEntity config) async {
    // Alta: la lista es perezosa y en la pantalla de prueba por defecto los
    // últimos elementos ni se construyen.
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    when(() => repository.getConfig()).thenAnswer((_) async => Right(config));
    final bloc = DispatchConfigBloc(repository: repository)
      ..add(DispatchConfigLoadRequested());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: const DispatchConfigView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the superuser sees the switch, the rings and a disabled Save', (tester) async {
    await open(tester, _config());

    expect(find.text('Los administradores pueden editar'), findsOneWidget);
    expect(find.text('Anillo 1'), findsOneWidget);
    expect(find.text('Anillo 2'), findsOneWidget);
    expect(find.text('Agregar anillo'), findsOneWidget);
    expect(find.text('Solo lectura', findRichText: true), findsNothing);
    final save = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Guardar cambios'),
    );
    expect(save.onPressed, isNull, reason: 'sin cambios no hay nada que guardar');
  });

  testWidgets('an admin without permission sees everything read-only', (tester) async {
    await open(tester, _config(canEdit: false, canChangeAdminEditing: false));

    expect(find.textContaining('Solo lectura'), findsOneWidget);
    expect(find.text('Los administradores pueden editar'), findsNothing);
    expect(find.text('Guardar cambios'), findsNothing);
    expect(find.text('Agregar anillo'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    // los valores se ven, pero los campos están deshabilitados
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, isNotEmpty);
    expect(fields.every((f) => f.enabled == false), isTrue);
    expect(find.text('Anillo 1'), findsOneWidget);
  });

  testWidgets('an admin with the switch on edits but does not see the switch', (tester) async {
    await open(tester, _config(canChangeAdminEditing: false, adminsCanEdit: true));

    expect(find.textContaining('Solo lectura'), findsNothing);
    expect(find.text('Los administradores pueden editar'), findsNothing);
    expect(find.text('Guardar cambios'), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((f) => f.enabled == true), isTrue);
  });

  testWidgets('editing a value enables Save, and an invalid one shows the error and blocks it', (tester) async {
    await open(tester, _config());
    // campo "Antigüedad máxima (s)": el último TextField (no se busca por su
    // valor, que cambia al escribir)
    final age = find.byType(TextField).last;

    await tester.enterText(age, '60');
    await tester.pump();
    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Guardar cambios')).onPressed,
      isNotNull,
    );

    await tester.enterText(age, '5');
    await tester.pump();
    expect(find.text('Entre 30 y 600 s'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Guardar cambios')).onPressed,
      isNull,
    );
  });

  testWidgets('a radius that does not grow is flagged on its ring', (tester) async {
    await open(tester, _config());

    // El segundo anillo (6 km) pasa a 3 km: igual que el primero
    await tester.enterText(find.widgetWithText(TextField, '6'), '3');
    await tester.pump();

    expect(find.text('Debe ser mayor que el anillo anterior'), findsOneWidget);
  });

  testWidgets('the summary follows the draft (total search time)', (tester) async {
    await open(tester, _config());
    expect(find.text('Búsqueda total: 20 s'), findsOneWidget);

    await tester.tap(find.text('Agregar anillo'));
    await tester.pump();

    expect(find.text('Búsqueda total: 30 s'), findsOneWidget);
    expect(find.text('Anillo 3'), findsOneWidget);
  });

  testWidgets('saving asks for confirmation before sending anything', (tester) async {
    await open(tester, _config());
    await tester.enterText(find.widgetWithText(TextField, '45'), '60');
    await tester.pump();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('¿Aplicar los cambios?'), findsOneWidget);
    verifyNever(
      () => repository.saveConfig(
        rings: any(named: 'rings'),
        locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
        expectedVersion: any(named: 'expectedVersion'),
      ),
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(
      () => repository.saveConfig(
        rings: any(named: 'rings'),
        locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
        expectedVersion: any(named: 'expectedVersion'),
      ),
    );
  });

  testWidgets('confirming sends the draft with the loaded version', (tester) async {
    await open(tester, _config());
    when(
      () => repository.saveConfig(
        rings: any(named: 'rings'),
        locationMaxAgeSeconds: any(named: 'locationMaxAgeSeconds'),
        expectedVersion: any(named: 'expectedVersion'),
      ),
    ).thenAnswer((_) async => Right(_config()));
    await tester.enterText(find.widgetWithText(TextField, '45'), '60');
    await tester.pump();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pump();

    verify(
      () => repository.saveConfig(
        rings: any(named: 'rings'),
        locationMaxAgeSeconds: 60,
        expectedVersion: 0,
      ),
    ).called(1);
    await letToastsFinish(tester);
  });

  testWidgets('moving the switch asks first, then sends it', (tester) async {
    await open(tester, _config());
    when(() => repository.setAdminEditing(enabled: true)).thenAnswer(
      (_) async => Right(_config(adminsCanEdit: true)),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('¿Permitir que los administradores editen?'), findsOneWidget);
    verifyNever(() => repository.setAdminEditing(enabled: any(named: 'enabled')));

    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    verify(() => repository.setAdminEditing(enabled: true)).called(1);
    await letToastsFinish(tester);
  });
}
