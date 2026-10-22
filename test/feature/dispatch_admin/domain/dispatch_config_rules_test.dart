import 'package:driver_app/feature/dispatch_admin/domain/dispatch_config_rules.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_limits_entity.dart';
import 'package:driver_app/feature/dispatch_admin/domain/entity/dispatch_ring_entity.dart';
import 'package:flutter_test/flutter_test.dart';

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

DispatchRingEntity _ring(int radius, {int wait = 10, int max = 10}) =>
    DispatchRingEntity(radiusMeters: radius, waitSeconds: wait, maxDrivers: max);

DispatchDraftValidation _validate(
  List<DispatchRingEntity> rings, {
  int age = 45,
}) => validateDispatchDraft(
  rings: rings,
  locationMaxAgeSeconds: age,
  limits: _limits,
);

void main() {
  test('a valid draft has no issues', () {
    final result = _validate([_ring(3000), _ring(6000), _ring(9000)]);

    expect(result.isValid, isTrue);
    expect(result.ringIssues, isEmpty);
    expect(result.draftIssues, isEmpty);
  });

  test('an empty list is rejected (it would switch dispatching off)', () {
    expect(_validate([]).draftIssues, {DispatchDraftIssue.noRings});
  });

  test('more rings than the server allows is rejected, the maximum is fine', () {
    final six = [for (var i = 1; i <= 6; i++) _ring(i * 1000, wait: 5)];
    final seven = [for (var i = 1; i <= 7; i++) _ring(i * 1000, wait: 5)];

    expect(_validate(six).isValid, isTrue);
    expect(_validate(seven).draftIssues, {DispatchDraftIssue.tooManyRings});
  });

  test('radius must be inside the range, both extremes included', () {
    expect(_validate([_ring(99)]).ringIssues[0], {
      DispatchRingIssue.radiusOutOfRange,
    });
    expect(_validate([_ring(50001)]).ringIssues[0], {
      DispatchRingIssue.radiusOutOfRange,
    });
    expect(_validate([_ring(100)]).isValid, isTrue);
    expect(_validate([_ring(50000)]).isValid, isTrue);
  });

  test('a ring whose radius does not grow is flagged on THAT ring', () {
    final result = _validate([_ring(3000), _ring(3000), _ring(9000)]);

    expect(result.ringIssues.keys, [1]);
    expect(result.ringIssues[1], {DispatchRingIssue.radiusNotIncreasing});
  });

  test('a smaller radius than the previous one is flagged as not increasing', () {
    final result = _validate([_ring(6000), _ring(3000)]);

    expect(result.ringIssues[1], {DispatchRingIssue.radiusNotIncreasing});
  });

  test('wait and max drivers are range checked', () {
    expect(_validate([_ring(3000, wait: 0)]).ringIssues[0], {
      DispatchRingIssue.waitOutOfRange,
    });
    expect(_validate([_ring(3000, wait: 121)]).ringIssues[0], {
      DispatchRingIssue.waitOutOfRange,
    });
    expect(_validate([_ring(3000, max: 0)]).ringIssues[0], {
      DispatchRingIssue.maxDriversOutOfRange,
    });
    expect(_validate([_ring(3000, max: 101)]).ringIssues[0], {
      DispatchRingIssue.maxDriversOutOfRange,
    });
  });

  test('several problems on one ring are all reported', () {
    final result = _validate([_ring(0, wait: 0, max: 0)]);

    expect(result.ringIssues[0], {
      DispatchRingIssue.radiusOutOfRange,
      DispatchRingIssue.waitOutOfRange,
      DispatchRingIssue.maxDriversOutOfRange,
    });
  });

  test('the whole search cannot last longer than the maximum', () {
    // 3 x 41 = 123 > 120
    final slow = [
      _ring(1000, wait: 41),
      _ring(2000, wait: 41),
      _ring(3000, wait: 41),
    ];
    final exact = [_ring(1000, wait: 60), _ring(2000, wait: 60)];

    expect(_validate(slow).draftIssues, {DispatchDraftIssue.totalWaitTooLong});
    expect(_validate(exact).isValid, isTrue);
  });

  test('location freshness respects the minimum and maximum', () {
    final rings = [_ring(3000)];

    expect(_validate(rings, age: 29).draftIssues, {
      DispatchDraftIssue.locationAgeOutOfRange,
    });
    expect(_validate(rings, age: 601).draftIssues, {
      DispatchDraftIssue.locationAgeOutOfRange,
    });
    expect(_validate(rings, age: 30).isValid, isTrue);
    expect(_validate(rings, age: 600).isValid, isTrue);
  });

  test('totalWaitSecondsOf sums the waits', () {
    expect(
      totalWaitSecondsOf(
        rings: [_ring(1000, wait: 5), _ring(2000, wait: 7), _ring(3000)],
      ),
      22,
    );
    expect(totalWaitSecondsOf(rings: []), 0);
  });
}
