import 'package:driver_app/feature/chat/presentation/bloc/chat_bloc.dart';
import 'package:driver_app/feature/chat/presentation/screen/chat_screen.dart';
import 'package:driver_app/feature/incoming_request/domain/entity/incoming_request_entity.dart';
import 'package:driver_app/shared/presentation/component/app_toast.dart';
import 'package:driver_app/shared/presentation/component/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:map_launcher/map_launcher.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/chat_presence/service/pending_chat_navigation_tracker.dart';
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
  late final ChatBloc _chatBloc;
  final PendingChatNavigationTracker _pendingChat =
      GetIt.instance<PendingChatNavigationTracker>();

  @override
  void initState() {
    super.initState();
    _tripBloc = context.read<TripBloc>();
    _tripBloc.add(StartWatchingTrip(passengerId: widget.request.userId));
    // Arranca acá (no en ChatScreen) para que el contador de no-leídos siga
    // actualizándose mientras el conductor está en TripScreen sin haber
    // entrado al chat.
    _chatBloc = GetIt.instance<ChatBloc>();
    debugPrint(
      'ChatFlowDebug | TripScreen.initState -> rideId=${widget.request.rideId}',
    );
    _chatBloc.add(WatchMessages(rideId: widget.request.rideId));

    // Cubre los 3 casos de un push de chat tocado (ver
    // PushNotificationsServiceImpl): si ya había un pedido pendiente de
    // antes de montarse (cold-start) lo consume de una vez; si llega uno
    // mientras esta pantalla sigue montada (foreground/background con la
    // app viva), el listener reacciona al instante.
    _pendingChat.pendingRideId.addListener(_onPendingChatChanged);
    _onPendingChatChanged();
  }

  void _onPendingChatChanged() {
    if (_pendingChat.consumeIfMatches(rideId: widget.request.rideId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openChat();
      });
    }
  }

  @override
  void dispose() {
    _pendingChat.pendingRideId.removeListener(_onPendingChatChanged);
    _tripBloc.add(StopWatchingTrip());
    _chatBloc.add(StopWatchingMessages());
    super.dispose();
  }

  void _openChat() {
    context.push(
      chatRoute.route,
      extra: ChatScreenArgs(
        rideId: widget.request.rideId,
        passengerId: widget.request.userId,
      ),
    );
  }

  Future<void> _onTripCancelled(String? cancelledBy) async {
    if (cancelledBy == 'passenger') {
      GetIt.instance<FeedbackService>().announce(
        AppLocalizations.of(context).tripPassengerCancelledAnnouncement,
        withVibration: true,
      );
      await PassengerCancelledDialog.show(context: context);

      if (!mounted) return;
      context.go(bookingRoute.route);

    }
  }

  void _onPassengerOnTheWay() {
    GetIt.instance<FeedbackService>().announce(
      AppLocalizations.of(context).tripPassengerOnTheWay,
      withVibration: true,
    );
    AppToast.success(
      context,
      message: AppLocalizations.of(context).tripPassengerOnTheWay,
    );
  }

  void _onTripCompleted() {
    context.go(bookingRoute.route);
  }

  // No pasa por un Bloc/repositorio (igual que GeolocatorService en
  // IncomingRequestTile): abrir una app externa es una capacidad de
  // plataforma sin estado ni datos que modelar, no una fuente de datos del
  // dominio. map_launcher lanza si Google Maps no está instalado en el
  // dispositivo -- se captura y se avisa con un toast en vez de dejar
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
      AppToast.error(
        context,
        message: AppLocalizations.of(context).tripOpenMapsFailed,
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
            AppLocalizations.of(context).tripInProgressTitle,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            BlocBuilder<ChatBloc, ChatState>(
              bloc: _chatBloc,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ChatButton(
                    unreadCount: state.unreadCount,
                    onTap: _openChat,
                  ),
                );
              },
            ),
          ],
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
                                  ? AppLocalizations.of(context).tripArrivedSending
                                  : AppLocalizations.of(context).tripArrived,
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
                                  ? AppLocalizations.of(context).tripFinishing
                                  : AppLocalizations.of(context).tripFinish,
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
                          AppLocalizations.of(context).tripCancel,
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
                  AppLocalizations.of(context).tripPassengerLabel,
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
                      AppLocalizations.of(context).commonPickupPoint,
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
          _buildOpenMapsButton(colorScheme),
        ],
      ),
    );
  }

  // Antes era un OutlinedButton.icon con un ícono genérico -- se reemplaza
  // por una tarjeta con el ícono real de Google Maps en su propio tile
  // (mismo lenguaje visual que _buildPassengerCard/_buildPickupCard) más un
  // subtítulo, para que se lea de una como "esto abre otra app para
  // navegar" y no como un simple botón de texto.
  Widget _buildOpenMapsButton(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openInGoogleMaps,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Image.asset('assets/icons/maps.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).tripOpenInMaps,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).tripNavigateToPickup,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Chip circular tintado (en vez de un IconButton "pelado") para que el
// acceso al chat se lea como una acción de primer nivel del AppBar, no como
// un ícono suelto -- mismo lenguaje visual que _buildOpenMapsButton.
class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primary.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: Tooltip(
        message: AppLocalizations.of(context).chatTitle,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: Image.asset(
                'assets/icons/chat_bubble.png',
                width: 22,
                height: 22,
                color: colorScheme.primary,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
