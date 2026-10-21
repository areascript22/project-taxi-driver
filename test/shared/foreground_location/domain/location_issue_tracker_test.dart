import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/shared/foreground_location/domain/location_issue_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

// Decide cuando avisarle al conductor de que no hay ubicacion. Es una clase pura:
// sin plugins ni reloj.
void main() {
  group('LocationIssueTracker', () {
    test('one or two failures are not a problem yet (a GPS can take a moment to fix)', () {
      final tracker = LocationIssueTracker();

      final first = tracker.onFailure(code: FailureCode.gpsDisabled);
      final second = tracker.onFailure(code: FailureCode.gpsDisabled);

      expect(first.changed, isFalse);
      expect(second.changed, isFalse);
      expect(tracker.announced, isNull);
    });

    test('announces the issue on the 3rd consecutive failure', () {
      final tracker = LocationIssueTracker();
      tracker.onFailure(code: FailureCode.gpsDisabled);
      tracker.onFailure(code: FailureCode.gpsDisabled);

      final third = tracker.onFailure(code: FailureCode.gpsDisabled);

      expect(third.changed, isTrue);
      expect(third.issue, FailureCode.gpsDisabled);
      expect(tracker.announced, FailureCode.gpsDisabled);
    });

    test('does not repeat the same announcement while the problem continues', () {
      final tracker = LocationIssueTracker(failureThreshold: 1);
      tracker.onFailure(code: FailureCode.gpsDisabled);

      final again = tracker.onFailure(code: FailureCode.gpsDisabled);

      expect(again.changed, isFalse);
      expect(again.issue, FailureCode.gpsDisabled);
    });

    test('announces again when the reason changes', () {
      final tracker = LocationIssueTracker(failureThreshold: 1);
      tracker.onFailure(code: FailureCode.gpsDisabled);

      final other = tracker.onFailure(code: FailureCode.locationPermissionDenied);

      expect(other.changed, isTrue);
      expect(other.issue, FailureCode.locationPermissionDenied);
    });

    test('one good reading resolves an announced issue', () {
      final tracker = LocationIssueTracker(failureThreshold: 1);
      tracker.onFailure(code: FailureCode.gpsDisabled);

      final ok = tracker.onSuccess();

      expect(ok.changed, isTrue);
      expect(ok.issue, isNull);
      expect(tracker.announced, isNull);
    });

    test('a good reading with nothing announced changes nothing', () {
      final tracker = LocationIssueTracker();

      expect(tracker.onSuccess().changed, isFalse);
    });

    // "Seguidos": una lectura buena en medio reinicia la cuenta.
    test('a good reading in between restarts the count', () {
      final tracker = LocationIssueTracker();
      tracker.onFailure(code: FailureCode.gpsDisabled);
      tracker.onFailure(code: FailureCode.gpsDisabled);
      tracker.onSuccess();

      final afterReset = tracker.onFailure(code: FailureCode.gpsDisabled);

      expect(afterReset.changed, isFalse, reason: 'vuelve a necesitar 3 fallos seguidos');
    });

    test('an unknown GPS error is announced as locationUnavailable', () {
      final tracker = LocationIssueTracker(failureThreshold: 1);

      final update = tracker.onFailure(code: FailureCode.unexpected);

      expect(update.issue, FailureCode.locationUnavailable);
    });
  });

  group('message between the service isolate and the app', () {
    test('an issue survives encode -> decode', () {
      for (final code in [
        FailureCode.gpsDisabled,
        FailureCode.locationPermissionDenied,
        FailureCode.locationUnavailable,
      ]) {
        expect(decodeLocationIssue(encodeLocationIssue(code)), code);
      }
    });

    test('"no issue" survives encode -> decode', () {
      expect(decodeLocationIssue(encodeLocationIssue(null)), isNull);
    });

    test('a null, empty or unknown message decodes to "no issue" and never throws', () {
      expect(decodeLocationIssue(null), isNull);
      expect(decodeLocationIssue(<String, dynamic>{}), isNull);
      expect(decodeLocationIssue({'issue': 'nonexistentCode'}), isNull);
      expect(decodeLocationIssue({'issue': 42}), isNull);
    });
  });
}
