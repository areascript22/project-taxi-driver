import 'package:driver_app/shared/foreground_location/domain/location_report_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = LocationReportPolicy(
    minMovementMeters: 5,
    heartbeat: Duration(seconds: 20),
  );

  test('the first report always goes out', () {
    expect(policy.shouldReport(), isTrue);
  });

  test('a report is sent when the driver moved enough', () {
    expect(
      policy.shouldReport(
        movedMeters: 12,
        sinceLastReport: const Duration(seconds: 5),
      ),
      isTrue,
    );
  });

  test('GPS jitter right after a report is not sent', () {
    expect(
      policy.shouldReport(
        movedMeters: 1.5,
        sinceLastReport: const Duration(seconds: 5),
      ),
      isFalse,
    );
  });

  // Sin el latido, un conductor parado esperando un pedido dejaria de
  // reportar y el servidor lo sacaria del despacho por ubicacion vieja.
  test('a parked driver still reports once the heartbeat elapses', () {
    expect(
      policy.shouldReport(
        movedMeters: 0,
        sinceLastReport: const Duration(seconds: 20),
      ),
      isTrue,
    );
    expect(
      policy.shouldReport(
        movedMeters: 0,
        sinceLastReport: const Duration(seconds: 19),
      ),
      isFalse,
    );
  });

  test('the movement threshold is inclusive', () {
    expect(
      policy.shouldReport(
        movedMeters: 5,
        sinceLastReport: const Duration(seconds: 1),
      ),
      isTrue,
    );
  });

  test('the default heartbeat is well under the server freshness window (45 s)', () {
    expect(
      const LocationReportPolicy().heartbeat,
      lessThan(const Duration(seconds: 45)),
    );
  });
}
