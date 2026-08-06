import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:flutter/material.dart';

// Placeholder: pantalla de "viaje en curso" para el conductor tras aceptar
// una carrera. Todavía no maneja navegación al punto de recogida, cambios
// de estado del viaje (llegó, inició, finalizó) ni comunicación con el
// pasajero — solo confirma visualmente que la carrera fue aceptada.
class TripScreen extends StatelessWidget {
  final IncomingRequestEntity request;

  const TripScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Viaje en curso',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pasajero',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              request.passenger.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Punto de recogida',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              request.pickupLocation.address,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
