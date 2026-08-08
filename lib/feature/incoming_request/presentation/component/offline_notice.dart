import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/foreground_location/presentation/bloc/foreground_service_bloc.dart';

// Se muestra en el body de IncomingRequestScreen cuando el toggle está
// apagado: mientras esté así, el conductor no está escuchando peticiones de
// Firebase (ver incoming_request_screen.dart).
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE94560).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gps_off,
                color: Color(0xFFE94560),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Estás offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Activa el switch en la parte superior para empezar a recibir peticiones de carrera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    () => context.read<ForegroundServiceBloc>().add(
                      ForegroundServiceToggled(),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Conectarme',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
