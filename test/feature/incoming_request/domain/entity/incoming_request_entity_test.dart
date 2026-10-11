import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // La forma que escribe el despacho en driver_offers/{uid}/{passengerId}.
  Map<String, dynamic> offer({int? expiresAt}) => {
    'rideId': 'p1_1700000000000',
    'passengerId': 'p1',
    'passengerName': 'Ana Perez',
    'pickup': {
      'latitude': -1.6635,
      'longitude': -78.6546,
      'address': 'Av. Daniel Leon Borja',
      'sector': 'La Saboya',
    },
    'ring': 1,
    'distanceMeters': 512.3,
    if (expiresAt != null) 'expiresAt': expiresAt,
  };

  group('fromOffer', () {
    test('maps the offer to the entity the list and the tiles already use', () {
      final entity = IncomingRequestEntity.fromOffer(offer());

      expect(entity.rideId, 'p1_1700000000000');
      expect(entity.userId, 'p1');
      expect(entity.status, 'pending');
      expect(entity.passenger.name, 'Ana Perez');
      expect(entity.pickupLocation.sector, 'La Saboya');
      expect(entity.pickupLocation.address, 'Av. Daniel Leon Borja');
      expect(entity.pickupLocation.latitude, -1.6635);
      expect(entity.pickupLocation.longitude, -78.6546);
    });

    test('tolerates missing optional fields', () {
      final entity = IncomingRequestEntity.fromOffer({'rideId': 'r1', 'passengerId': 'p1'});

      expect(entity.passenger.name, '');
      expect(entity.pickupLocation.sector, '');
      expect(entity.pickupLocation.latitude, 0.0);
    });

    test('reads integer coordinates as doubles', () {
      final entity = IncomingRequestEntity.fromOffer({
        'rideId': 'r1',
        'passengerId': 'p1',
        'pickup': {'latitude': -2, 'longitude': -78},
      });

      expect(entity.pickupLocation.latitude, -2.0);
    });
  });

  group('isOfferExpired', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('an offer past its expiry is expired', () {
      expect(
        IncomingRequestEntity.isOfferExpired(
          offer(expiresAt: 1699999999000),
          now: now,
        ),
        isTrue,
      );
    });

    test('an offer expiring right now is expired', () {
      expect(
        IncomingRequestEntity.isOfferExpired(
          offer(expiresAt: 1700000000000),
          now: now,
        ),
        isTrue,
      );
    });

    test('an offer with time left is not expired', () {
      expect(
        IncomingRequestEntity.isOfferExpired(
          offer(expiresAt: 1700000030000),
          now: now,
        ),
        isFalse,
      );
    });

    test('an offer without expiry never expires', () {
      expect(IncomingRequestEntity.isOfferExpired(offer(), now: now), isFalse);
    });
  });
}
