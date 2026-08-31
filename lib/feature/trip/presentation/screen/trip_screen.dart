import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/shared/presentation/component/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:map_launcher/map_launcher.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/feedback/feedback_service.dart';
import '../bloc/trip_bloc.dart';
import 'widgets/confirm_cancel_trip_dialog.dart';
import 'widgets/passenger_cancelled_dialog.dart';

// Pantalla de "viaje en curso" para el conductor tras aceptar una carrera.
// Todavía no maneja navegación al punto de recogida, pero sí cubre el ciclo
// de estados del viaje (llegó, pasajero en camino, finalizó) y la
// comunicación básica con el pasajero vía Firebase.
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

  void _onPassengerOnTheWay() {
    GetIt.instance<FeedbackService>().announce(
      'El pasajero está en camino al auto',
      withVibration: true,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El pasajero está en camino al auto')),
    );
  }

  void _onTripCompleted() {
    context.go(bookingRoute.route);
  }

  // No pasa por un Bloc/repositorio (igual que GeolocatorService en
  // IncomingRequestTile): abrir una app externa es una capacidad de
  // plataforma sin estado ni datos que modelar, no una fuente de datos del
  // dominio. map_launcher lanza si Google Maps no está instalado en el
  // dispositivo -- se captura y se avisa con un snackbar en vez de dejar
  // que la excepción suba sin manejar.
  Future<void> _openInGoogleMaps() async {
    try {
      await MapLauncher.showMarker(
        mapType: MapType.google,
        coords: Coords(
          widget.request.pickupLocation.latitude,
          widget.request.pickupLocation.longitude,
        ),
        title: widget.request.passenger.name,
        description: widget.request.pickupLocation.address,
      );
    } catch (e) {
      debugPrint('TripDebug | Error al abrir Google Maps: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps. ¿Está instalado?'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<TripBloc, TripState>(
          listenWhen:
              (previous, current) =>
                  !previous.isCancelled && current.isCancelled,
          listener: (context, state) => _onTripCancelled(state.cancelledBy),
        ),
        BlocListener<TripBloc, TripState>(
          listenWhen:
              (previous, current) =>
                  previous.status != 'tripStarted' &&
                  current.status == 'tripStarted',
          listener: (context, state) => _onPassengerOnTheWay(),
        ),
        BlocListener<TripBloc, TripState>(
          listenWhen:
              (previous, current) =>
                  !previous.isCompleted && current.isCompleted,
          listener: (context, state) => _onTripCompleted(),
        ),
      ],
      child: Scaffold(
        backgroundColor: context.appColors.backgroundGradient.last,
        appBar: AppBar(
          title: Text(
            'Viaje en curso',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPassengerCard(colorScheme),
              const SizedBox(height: 16),
              _buildPickupCard(colorScheme),
              const Spacer(),
              BlocBuilder<TripBloc, TripState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.status == 'driverAssigned') ...[
                        CustomButton(
                          textButton:
                              state.isMarkingArrived
                                  ? 'Enviando...'
                                  : 'He llegado',
                          backgroundColor: context.appColors.success,
                          onTap:
                              state.isMarkingArrived
                                  ? null
                                  : () => context.read<TripBloc>().add(
                                    DriverArrivedRequested(
                                      passengerId: widget.request.userId,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.status == 'tripStarted') ...[
                        CustomButton(
                          textButton:
                              state.isCompleting
                                  ? 'Finalizando...'
                                  : 'Finalizar viaje',
                          backgroundColor: context.appColors.success,
                          onTap:
                              state.isCompleting
                                  ? null
                                  : () => context.read<TripBloc>().add(
                                    CompleteTripRequested(
                                      passengerId: widget.request.userId,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton(
                        onPressed: () {
                          ConfirmCancelTripDialog.show(
                            context: context,
                            passengerId: widget.request.userId,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancelar carrera',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 150,),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
              backgroundImage: NetworkImage(
                widget.request.passenger.profileImage,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pasajero',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.request.passenger.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Punto de recogida',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.request.pickupLocation.address,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openInGoogleMaps,
              icon: Icon(Icons.map_outlined, color: colorScheme.primary, size: 20),
              label: Text(
                'Abrir en Google Maps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
