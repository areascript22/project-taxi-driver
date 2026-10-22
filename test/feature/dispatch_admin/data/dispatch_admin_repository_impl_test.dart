import 'package:dio/dio.dart';
import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/feature/dispatch_admin/data/repository/dispatch_admin_repository_impl.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_change_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_ring_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _configJson({
  int version = 3,
  bool canEdit = true,
  bool canChangeAdminEditing = true,
  bool adminsCanEdit = false,
  String? updatedAt = '2026-10-21T20:15:30.123456Z',
}) => {
  'rings': [
    {'number': 1, 'radiusMeters': 3000, 'waitSeconds': 10, 'maxDrivers': 10},
    {'number': 2, 'radiusMeters': 6000, 'waitSeconds': 12, 'maxDrivers': 8},
  ],
  'locationMaxAgeSeconds': 45,
  'adminsCanEdit': adminsCanEdit,
  'version': version,
  'updatedAt': updatedAt,
  'updatedByName': 'Super Uno',
  'totalWaitSeconds': 22,
  'requestExpirySeconds': 35,
  'canEdit': canEdit,
  'canChangeAdminEditing': canChangeAdminEditing,
  'limits': {
    'maxRings': 6,
    'maxTotalWaitSeconds': 120,
    'minLocationMaxAgeSeconds': 30,
    'maxLocationMaxAgeSeconds': 600,
    'minRadiusMeters': 100,
    'maxRadiusMeters': 50000,
    'minWaitSeconds': 1,
    'maxWaitSeconds': 120,
    'minMaxDrivers': 1,
    'maxMaxDrivers': 100,
  },
};

Response<dynamic> _ok(Object? body) => Response(
  requestOptions: RequestOptions(path: '/x'),
  statusCode: 200,
  data: body,
);

DioException _status(int code) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: code),
  type: DioExceptionType.badResponse,
);

void main() {
  late MockDio dio;
  late DispatchAdminRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    repository = DispatchAdminRepositoryImpl(dio: dio);
  });

  group('getConfig', () {
    test('maps the response to an entity, including limits and permissions', () async {
      when(() => dio.get(any())).thenAnswer((_) async => _ok(_configJson()));

      final config = (await repository.getConfig()).getOrElse(
        () => throw StateError('expected Right'),
      );

      expect(config.rings, hasLength(2));
      expect(config.rings[1].radiusMeters, 6000);
      expect(config.rings[1].waitSeconds, 12);
      expect(config.rings[1].maxDrivers, 8);
      expect(config.locationMaxAgeSeconds, 45);
      expect(config.version, 3);
      expect(config.updatedByName, 'Super Uno');
      expect(config.updatedAt, isNotNull);
      expect(config.totalWaitSeconds, 22);
      expect(config.requestExpirySeconds, 35);
      expect(config.canEdit, isTrue);
      expect(config.canChangeAdminEditing, isTrue);
      expect(config.limits.maxRings, 6);
      expect(config.limits.minLocationMaxAgeSeconds, 30);
      verify(() => dio.get('/api/admin/dispatch/config')).called(1);
    });

    test('an unreadable date does not break the screen', () async {
      when(() => dio.get(any())).thenAnswer(
        (_) async => _ok(_configJson(updatedAt: 'not-a-date')),
      );

      final config = (await repository.getConfig()).getOrElse(
        () => throw StateError('expected Right'),
      );

      expect(config.updatedAt, isNull);
    });

    test('maps 403 to noPermission and other failures to the fetch code', () async {
      when(() => dio.get(any())).thenThrow(_status(403));
      expect(
        (await repository.getConfig()).swap().getOrElse(() => throw StateError('x')).code,
        FailureCode.noPermission,
      );

      when(() => dio.get(any())).thenThrow(_status(500));
      expect(
        (await repository.getConfig()).swap().getOrElse(() => throw StateError('x')).code,
        FailureCode.dispatchConfigFetchFailed,
      );

      when(() => dio.get(any())).thenAnswer((_) async => _ok('garbage'));
      expect(
        (await repository.getConfig()).swap().getOrElse(() => throw StateError('x')).code,
        FailureCode.dispatchConfigFetchFailed,
      );
    });
  });

  group('saveConfig', () {
    const rings = [
      DispatchRingEntity(radiusMeters: 2000, waitSeconds: 8, maxDrivers: 5),
      DispatchRingEntity(radiusMeters: 5000, waitSeconds: 12, maxDrivers: 7),
    ];

    test('sends the whole config with the version seen and never retries', () async {
      when(
        () => dio.put(any(), data: any(named: 'data'), options: any(named: 'options')),
      ).thenAnswer((_) async => _ok(_configJson(version: 4)));

      final saved = (await repository.saveConfig(
        rings: rings,
        locationMaxAgeSeconds: 60,
        expectedVersion: 3,
      )).getOrElse(() => throw StateError('expected Right'));

      expect(saved.version, 4);
      final captured = verify(
        () => dio.put(
          '/api/admin/dispatch/config',
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      expect(captured[0], {
        'rings': [
          {'radiusMeters': 2000, 'waitSeconds': 8, 'maxDrivers': 5},
          {'radiusMeters': 5000, 'waitSeconds': 12, 'maxDrivers': 7},
        ],
        'locationMaxAgeSeconds': 60,
        'expectedVersion': 3,
      });
      // sin 'number': lo da la posición
      expect((captured[0]['rings'] as List).first.containsKey('number'), isFalse);
      // un reintento llegaría con la versión vieja y daría un conflicto falso
      expect(
        (captured[1] as Options).extra!.values,
        contains(true),
        reason: 'disableRetry marca el request en extra',
      );
    });

    test('maps 409 to conflict, 403 to noPermission and 400 to invalid', () async {
      Future<FailureCode> codeFor(int status) async {
        when(
          () => dio.put(any(), data: any(named: 'data'), options: any(named: 'options')),
        ).thenThrow(_status(status));
        final result = await repository.saveConfig(
          rings: rings,
          locationMaxAgeSeconds: 60,
          expectedVersion: 3,
        );
        return result.swap().getOrElse(() => throw StateError('x')).code;
      }

      expect(await codeFor(409), FailureCode.dispatchConfigConflict);
      expect(await codeFor(403), FailureCode.noPermission);
      expect(await codeFor(400), FailureCode.dispatchConfigInvalid);
      expect(await codeFor(500), FailureCode.dispatchConfigSaveFailed);
    });
  });

  group('setAdminEditing', () {
    test('sends the flag and returns the refreshed config', () async {
      when(
        () => dio.put(any(), data: any(named: 'data'), options: any(named: 'options')),
      ).thenAnswer((_) async => _ok(_configJson(adminsCanEdit: true)));

      final config = (await repository.setAdminEditing(enabled: true)).getOrElse(
        () => throw StateError('expected Right'),
      );

      expect(config.adminsCanEdit, isTrue);
      verify(
        () => dio.put(
          '/api/admin/dispatch/config/admin-editing',
          data: {'enabled': true},
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('a 403 (not the superuser) is noPermission', () async {
      when(
        () => dio.put(any(), data: any(named: 'data'), options: any(named: 'options')),
      ).thenThrow(_status(403));

      final result = await repository.setAdminEditing(enabled: true);

      expect(result.swap().getOrElse(() => throw StateError('x')).code, FailureCode.noPermission);
    });
  });

  group('getHistory', () {
    test('maps changes with both snapshots and the next cursor', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _ok({
          'changes': [
            {
              'id': 7,
              'changedAt': '2026-10-21T20:15:30Z',
              'changedByName': 'Super Uno',
              'type': 'config',
              'before': {
                'rings': [
                  {'number': 1, 'radiusMeters': 3000, 'waitSeconds': 10, 'maxDrivers': 10},
                ],
                'locationMaxAgeSeconds': 45,
                'adminsCanEdit': false,
              },
              'after': {
                'rings': [
                  {'number': 1, 'radiusMeters': 2000, 'waitSeconds': 8, 'maxDrivers': 5},
                ],
                'locationMaxAgeSeconds': 60,
                'adminsCanEdit': false,
              },
            },
            {
              'id': 6,
              'changedAt': '2026-10-20T10:00:00Z',
              'changedByName': '',
              'type': 'admins_can_edit',
              'before': {'rings': [], 'locationMaxAgeSeconds': 45, 'adminsCanEdit': false},
              'after': {'rings': [], 'locationMaxAgeSeconds': 45, 'adminsCanEdit': true},
            },
          ],
          'nextBeforeId': 6,
        }),
      );

      final page = (await repository.getHistory(limit: 20, beforeId: 8)).getOrElse(
        () => throw StateError('expected Right'),
      );

      expect(page.nextBeforeId, 6);
      expect(page.changes, hasLength(2));
      expect(page.changes[0].id, 7);
      expect(page.changes[0].type, DispatchChangeType.config);
      expect(page.changes[0].before.rings.single.radiusMeters, 3000);
      expect(page.changes[0].after.rings.single.radiusMeters, 2000);
      expect(page.changes[0].after.locationMaxAgeSeconds, 60);
      expect(page.changes[1].type, DispatchChangeType.adminsCanEdit);
      expect(page.changes[1].changedByName, '');
      expect(page.changes[1].after.adminsCanEdit, isTrue);
      verify(
        () => dio.get(
          '/api/admin/dispatch/config/history',
          queryParameters: {'limit': 20, 'beforeId': 8},
        ),
      ).called(1);
    });

    test('an unknown change type is shown as a config change, not a crash', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _ok({
          'changes': [
            {
              'id': 1,
              'changedAt': null,
              'changedByName': 'X',
              'type': 'something_new',
              'before': {'rings': [], 'locationMaxAgeSeconds': 45, 'adminsCanEdit': false},
              'after': {'rings': [], 'locationMaxAgeSeconds': 45, 'adminsCanEdit': false},
            },
          ],
          'nextBeforeId': null,
        }),
      );

      final page = (await repository.getHistory(limit: 20)).getOrElse(
        () => throw StateError('expected Right'),
      );

      expect(page.changes.single.type, DispatchChangeType.config);
      expect(page.changes.single.changedAt, isNull);
      expect(page.nextBeforeId, isNull);
    });

    test('omits beforeId on the first page and maps failures', () async {
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(_status(500));

      final result = await repository.getHistory(limit: 20);

      expect(
        result.swap().getOrElse(() => throw StateError('x')).code,
        FailureCode.dispatchHistoryFetchFailed,
      );
      verify(
        () => dio.get(any(), queryParameters: {'limit': 20}),
      ).called(1);
    });
  });
}
