import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/shared/presentation/component/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/feedback/feedback_service.dart';
import '../bloc/trip_bloc.dart';
import 'widgets/confirm_cancel_trip_dialog.dart';
import 'widgets/passenger_cancelled_dialog.dart';

// Pantalla de "viaje en curso" para el conductor tras aceptar una carrera.
// Todavía no maneja navegación al punto de recogida ni cambios de estado
// del viaje (llegó, inició, finalizó) o comunicación con el pasajero — solo
// confirma visualmente que la carrera fue aceptada y permite cancelarla.
class TripScreen extends StatelessWidget {
  final IncomingRequestEntity request;

  const TripScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<TripBloc>(),
      child: _TripView(request: request),
    );
  }
}

class _TripView extends StatefulWidget {
  final IncomingRequestEntity request;

  const _TripView({required this.request});

  @override
  State<_TripView> createState() => _TripViewState();
}

class _TripViewState extends State<_TripView> {
  late final TripBloc _tripBloc;

  @override
  void initState() {
    super.initState();
    _tripBloc = context.read<TripBloc>();
    _tripBloc.add(StartWatchingTrip(passengerId: widget.request.userId));
  }

  @override
  void dispose() {
    _tripBloc.add(StopWatchingTrip());
    super.dispose();
  }

  Future<void> _onTripCancelled(String? cancelledBy) async {
    if (cancelledBy == 'passenger') {
      GetIt.instance<FeedbackService>().announce(
        'El pasajero canceló la carrera',
        withVibration: true,
      );
      await PassengerCancelledDialog.show(context: context);

      if (!mounted) return;
      context.go(bookingRoute.route);

    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripBloc, TripState>(
      listenWhen:
          (previous, current) =>
              !previous.isCancelled && current.isCancelled,
      listener: (context, state) => _onTripCancelled(state.cancelledBy),
      child: Scaffold(
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
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.request.passenger.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Punto de recogida',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.request.pickupLocation.address,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ConfirmCancelTripDialog.show(
                      context: context,
                      passengerId: widget.request.userId,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE94560), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancelar carrera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE94560),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 150,),
            ],
          ),
        ),
      ),
    );
  }
}
