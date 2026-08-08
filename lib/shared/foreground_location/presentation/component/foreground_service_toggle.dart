import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/foreground_service_bloc.dart';

// Switch de prueba para el foreground service: solo confirma que el
// servicio (y su notificación persistente) prende y apaga correctamente.
// El tracking real de un viaje lo arranca/detiene TripBloc, no este switch.
class ForegroundServiceToggle extends StatelessWidget {
  const ForegroundServiceToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForegroundServiceBloc, ForegroundServiceState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.isRunning ? Icons.gps_fixed : Icons.gps_off,
              size: 18,
              color: Colors.white.withOpacity(0.7),
            ),
            Switch(
              value: state.isRunning,
              onChanged:
                  state.isProcessing
                      ? null
                      : (_) => context.read<ForegroundServiceBloc>().add(
                        ForegroundServiceToggled(),
                      ),
              activeColor: const Color(0xFFE94560),
            ),
          ],
        );
      },
    );
  }
}
