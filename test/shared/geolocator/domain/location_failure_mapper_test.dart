import 'dart:async';

import 'package:driver_app/core/error/errors.dart';
import 'package:driver_app/shared/geolocator/domain/location_failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

// Antes TODO error del GPS salia como `unexpected` y el conductor no sabia por
// que no recibia pedidos. Cada causa se arregla distinto, asi que cada una tiene
// su codigo.
void main() {
  group('locationFailureCodeOf', () {
    // Es lo que lanzaba el emulador: Android decia que la ubicacion estaba
    // encendida (isLocationServiceEnabled -> true) y aun asi la lectura fallaba
    // con "The location service on the device is disabled".
    test('location service disabled -> gpsDisabled', () {
      expect(
        locationFailureCodeOf(const LocationServiceDisabledException()),
        FailureCode.gpsDisabled,
      );
    });

    test('permission denied -> locationPermissionDenied', () {
      expect(
        locationFailureCodeOf(PermissionDeniedException('denied')),
        FailureCode.locationPermissionDenied,
      );
    });

    test('timed out without a fix -> locationUnavailable', () {
      expect(
        locationFailureCodeOf(TimeoutException('sin senal')),
        FailureCode.locationUnavailable,
      );
    });

    test('anything else stays unexpected (and is not swallowed as a known cause)', () {
      expect(locationFailureCodeOf(Exception('boom')), FailureCode.unexpected);
      expect(locationFailureCodeOf(StateError('x')), FailureCode.unexpected);
    });
  });
}
