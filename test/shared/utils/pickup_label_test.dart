import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/shared/utils/pickup_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickupLabel', () {
    // La regla del feature: el taxista escucha y ve el SECTOR, no la dirección
    // con número y cruce. La dirección exacta la ve al aceptar la carrera.
    test('el sector le gana a la direccion exacta', () {
      expect(
        pickupLabel(
          sector: 'La Condamine',
          address: 'Av. Daniel L. Borja 24-15 y Garcia Moreno',
        ),
        'La Condamine',
      );
    });

    // Carreras creadas antes de que existiera el campo, o puntos que
    // passenger_app no pudo resolver contra sus polígonos.
    test('sin sector cae a la direccion', () {
      expect(
        pickupLabel(sector: '', address: 'Av. Daniel L. Borja 24-15'),
        'Av. Daniel L. Borja 24-15',
      );
      expect(
        pickupLabel(sector: '   ', address: 'Av. Daniel L. Borja 24-15'),
        'Av. Daniel L. Borja 24-15',
      );
    });

    test('sin sector ni direccion devuelve null', () {
      expect(pickupLabel(sector: '', address: ''), isNull);
      expect(pickupLabel(sector: '  ', address: '  '), isNull);
    });

    test('recorta los espacios de los extremos', () {
      expect(pickupLabel(sector: ' Loma de Quito ', address: ''), 'Loma de Quito');
    });
  });

  // El campo es nuevo: las carreras que ya estaban en Realtime Database no lo
  // traen y no deben romper el parseo.
  group('PickupLocationEntity.fromMap', () {
    test('lee el sector cuando viene en el nodo', () {
      final pickup = PickupLocationEntity.fromMap({
        'address': 'Av. Daniel L. Borja',
        'sector': 'La Condamine',
        'latitude': -1.669,
        'longitude': -78.658,
      });

      expect(pickup.sector, 'La Condamine');
      expect(pickup.address, 'Av. Daniel L. Borja');
    });

    test('un nodo viejo sin sector queda con sector vacio, no con null', () {
      final pickup = PickupLocationEntity.fromMap({
        'address': 'Av. Daniel L. Borja',
        'latitude': -1.669,
        'longitude': -78.658,
      });

      expect(pickup.sector, isEmpty);
      expect(
        pickupLabel(sector: pickup.sector, address: pickup.address),
        'Av. Daniel L. Borja',
      );
    });
  });
}
