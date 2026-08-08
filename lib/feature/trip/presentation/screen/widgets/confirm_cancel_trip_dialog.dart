import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../bloc/trip_bloc.dart';
import '../../../../../shared/presentation/component/custom_loader.dart';

// Diálogo de confirmación para que el conductor cancele un viaje ya
// aceptado. Arquitectura basada en ConfirmCancelRideDialog (passenger_app).
class ConfirmCancelTripDialog extends StatelessWidget {
  final String passengerId;

  const ConfirmCancelTripDialog({super.key, required this.passengerId});

  static Future<void> show({
    required BuildContext context,
    required String passengerId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => BlocProvider.value(
            value: GetIt.instance<TripBloc>(),
            child: ConfirmCancelTripDialog(passengerId: passengerId),
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listenWhen:
          (previous, current) =>
          !previous.isCancelled && current.isCancelled,
      listener: (context, state) {
        if (context.canPop()) {
          context.pop();
          context.go(bookingRoute.route);
          return;
        }
        context.go(bookingRoute.route);
      },
      builder: (context, state) {
        final isCancelling = state.isCancelling;

        return PopScope(
          canPop: !isCancelling,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFE94560),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "¿Cancelar carrera?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Ya aceptaste esta carrera y el pasajero te está esperando. Si cancelas ahora podría afectar tu reputación como conductor.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              isCancelling
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.white.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Continuar carrera",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              !isCancelling
                                  ? () {
                                    context.read<TripBloc>().add(
                                      CancelTripRequested(
                                        passengerId: passengerId,
                                      ),
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isCancelling ? 14 : 14,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isCancelling
                                  ? CircularProgressIndicator()
                                  : const Text(
                                    "Cancelar carrera",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
