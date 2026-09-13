import 'dart:async';

import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/shared/feature/session/presentation/bloc/session/session_bloc.dart';
import 'package:driver_app/shared/geolocator/service/geolocator/geolocator_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

import '../bloc/incoming_request_bloc.dart';

class IncomingRequestTile extends StatefulWidget {
  final IncomingRequestEntity incomingRequestEntity;

  const IncomingRequestTile({super.key, required this.incomingRequestEntity});

  @override
  State<IncomingRequestTile> createState() => _IncomingRequestTileState();
}

class _IncomingRequestTileState extends State<IncomingRequestTile> {
  // Debe coincidir con PENDING_REQUEST_EXPIRY_SECONDS en el backend
  // (RideService.java): pasado ese tiempo sin que ningún conductor acepte,
  // el servidor auto-cancela la solicitud y esta tile desaparece sola de la
  // lista (deja de matchear el query status=='pending'). Este contador es
  // solo informativo para que el conductor sepa cuánto le queda.
  static const _autoExpireWindow = Duration(seconds: 35);
  // Bajo este umbral, el contador cambia a un color de alerta.
  static const _urgentThreshold = Duration(seconds: 10);

  bool _isRequestingLocation = false;
  Timer? _countdownTimer;
  late Duration _remaining;

  IncomingRequestEntity get incomingRequestEntity =>
      widget.incomingRequestEntity;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _computeRemaining();
      if (!mounted) return;
      setState(() => _remaining = remaining);
      if (remaining == Duration.zero) {
        _countdownTimer?.cancel();
      }
    });
  }

  Duration _computeRemaining() {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      incomingRequestEntity.createdAt,
    );
    final elapsed = DateTime.now().difference(createdAt);
    final remaining = _autoExpireWindow - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _onAcceptPressed() async {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is! SessionAuthenticated) return;

    setState(() => _isRequestingLocation = true);

    final geolocatorService = GetIt.instance<GeolocatorService>();

    final permissionResult =
        await geolocatorService.checkAndRequestPermission();

    final permission = permissionResult.fold((_) => null, (p) => p);
    final permissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!permissionGranted) {
      if (!mounted) return;
      setState(() => _isRequestingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se necesita acceso a tu ubicación para aceptar carreras.',
          ),
        ),
      );
      return;
    }

    final locationResult = await geolocatorService.getCurrentPosition();

    if (!mounted) return;

    locationResult.fold(
      (failure) {
        setState(() => _isRequestingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (driverLocation) {
        // No apagamos _isRequestingLocation acá: si lo hiciéramos, quedaría
        // una ventana entre este punto y el momento en que el Bloc procesa
        // el evento y emite AcceptRideStatus.loading, durante la cual
        // isBusy sería false y el botón se rehabilitaría, permitiendo un
        // segundo tap que dispare otra petición duplicada de aceptar. Se
        // apaga en el listener de resultado (ver más abajo).
        context.read<IncomingRequestBloc>().add(
          AcceptRideRequested(
            request: incomingRequestEntity,
            driverLocation: driverLocation,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<IncomingRequestBloc, IncomingRequestState>(
      listenWhen: (previous, current) {
        if (current is! IncomingRequestLoaded) return false;
        return current.processingRequest?.rideId == incomingRequestEntity.rideId &&
            current.acceptStatus != AcceptRideStatus.loading;
      },
      listener: (context, state) {
        if (_isRequestingLocation) {
          setState(() => _isRequestingLocation = false);
        }
      },
      child: _buildContent(context, colorScheme),
    );
  }

  Widget _buildCountdownBadge(ColorScheme colorScheme) {
    final isUrgent = _remaining <= _urgentThreshold;
    final badgeColor = isUrgent ? colorScheme.error : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Esperando conductor · ${_remaining.inSeconds}s',
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Fila Superior: Avatar y Nombre ---
          Row(
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
                  radius: 24,
                  backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                  backgroundImage: NetworkImage(
                    incomingRequestEntity.passenger.profileImage,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incomingRequestEntity.passenger.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCountdownBadge(colorScheme),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 16),

          // --- Fila Intermedia: Dirección ---
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incomingRequestEntity.pickupLocation.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          BlocBuilder<IncomingRequestBloc, IncomingRequestState>(
            builder: (context, state) {
              final isAcceptingThis =
                  state is IncomingRequestLoaded &&
                  state.acceptStatus == AcceptRideStatus.loading &&
                  state.processingRequest?.rideId == incomingRequestEntity.rideId;

              final isBusy = _isRequestingLocation || isAcceptingThis;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _onAcceptPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      isBusy
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : const Text(
                            'Aceptar carrera',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
