import 'package:driver_app/feature/incoming_request/presentation/component/incoming_request_tile.dart';
import 'package:driver_app/feature/incoming_request/presentation/component/location_permission_denied.dart';
import 'package:driver_app/feature/incoming_request/presentation/component/offline_notice.dart';
import 'package:driver_app/shared/foreground_location/presentation/bloc/foreground_service_bloc.dart';
import 'package:driver_app/shared/foreground_location/presentation/component/foreground_service_toggle.dart';
import 'package:driver_app/shared/foreground_location/service/driver_foreground_service.dart';
import 'package:driver_app/shared/geolocator/location/location_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/feedback/feedback_service.dart';
import '../bloc/incoming_request_bloc.dart';

class IncomingRequestScreen extends StatelessWidget {
  const IncomingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.instance<IncomingRequestBloc>()),
        BlocProvider(create: (_) => GetIt.instance<LocationBloc>()),
        BlocProvider(create: (_) => GetIt.instance<ForegroundServiceBloc>()),
      ],
      child: const IncomingRequestContent(),
    );
  }
}

class IncomingRequestContent extends StatefulWidget {
  const IncomingRequestContent({super.key});

  @override
  State<IncomingRequestContent> createState() => _IncomingRequestContentState();
}

class _IncomingRequestContentState extends State<IncomingRequestContent>
    with WidgetsBindingObserver {
  // Evita reabrir la configuración del sistema en cada recheck; solo la
  // primera vez que detectamos un bloqueo permanente redirigimos solos.
  bool _hasAutoOpenedSettings = false;

  // static (no de instancia): sigue viva mientras el proceso de la app siga
  // vivo, sin importar cuántas veces se entre/salga de esta pantalla por
  // navegación interna (context.go). Se reinicia solo con un kill real de
  // la app -- que es justo cuando SÍ queremos poder volver a evaluar si
  // corresponde saludar de nuevo.
  static bool _hasCheckedWelcomeThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ya no se dispara incondicionalmente: si llegan peticiones depende de
    // si el conductor está "online" (toggle), ver el BlocListener de
    // ForegroundServiceBloc más abajo.
    context.read<LocationBloc>().add(CheckAndRequestPermissionEvent());
    context.read<ForegroundServiceBloc>().add(ForegroundServiceStatusRequested());
    _maybePlayWelcome();
  }

  Future<void> _maybePlayWelcome() async {
    if (_hasCheckedWelcomeThisSession) return;
    _hasCheckedWelcomeThisSession = true;

    // Si el foreground service YA estaba corriendo al llegar acá (viaje en
    // curso, o el toggle se había dejado encendido antes de un kill de la
    // app), esto es continuación de una sesión anterior, no una entrada
    // nueva -- no repetir el saludo.
    final alreadyOnline =
        await GetIt.instance<DriverForegroundService>().isRunning();
    if (alreadyOnline) return;

    GetIt.instance<FeedbackService>().announce('Bienvenido a TaxiGo conductor');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // context.read<IncomingRequestBloc>().add(StopListeningRequests());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recheck silencioso (sin diálogo nativo) al volver de Configuración.
      context.read<LocationBloc>().add(CheckLocationPermissionEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<ForegroundServiceBloc, ForegroundServiceState>(
      listenWhen:
          (previous, current) => previous.isRunning != current.isRunning,
      listener: (context, state) {
        if (state.isRunning) {
          context.read<IncomingRequestBloc>().add(StartListeningRequests());
        } else {
          context.read<IncomingRequestBloc>().add(StopListeningRequests());
        }
      },
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.appColors.backgroundGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Peticiones Entrantes',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            // El toggle de prueba del foreground service solo tiene sentido
            // si el conductor ya dio permiso de ubicación.
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, locationState) {
                if (!locationState.isGranted) return const SizedBox.shrink();
                return const ForegroundServiceToggle();
              },
            ),
          ],
        ),
        body: BlocConsumer<LocationBloc, LocationState>(
          listenWhen:
              (previous, current) =>
                  previous.permissionStatus != current.permissionStatus,
          listener: (context, state) {
            if (state.isPermanentlyDenied && !_hasAutoOpenedSettings) {
              _hasAutoOpenedSettings = true;
              context.read<LocationBloc>().add(OpenAppSettingsEvent());
            }
          },
          builder: (context, locationState) {
            final isCheckingPermission =
                locationState.locationProcess ==
                    LocationProcess.initial ||
                locationState.locationProcess ==
                    LocationProcess.checkingPermissions;

            if (isCheckingPermission) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            if (!locationState.isGranted) {
              return LocationPermissionDenied(
                isPermanentlyDenied: locationState.isPermanentlyDenied,
                onEnablePermissionsTapped: () {
                  if (locationState.isPermanentlyDenied) {
                    context.read<LocationBloc>().add(OpenAppSettingsEvent());
                    return;
                  }
                  context.read<LocationBloc>().add(
                    CheckAndRequestPermissionEvent(),
                  );
                },
              );
            }

            return BlocBuilder<ForegroundServiceBloc, ForegroundServiceState>(
              builder: (context, fgState) {
                if (!fgState.hasLoadedStatus) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (!fgState.isRunning) {
                  return const OfflineNotice();
                }

                return BlocListener<IncomingRequestBloc, IncomingRequestState>(
                  listenWhen:
                      (previous, current) =>
                          previous is IncomingRequestLoaded &&
                          current is IncomingRequestLoaded &&
                          previous.acceptStatus != current.acceptStatus,
                  listener: (context, state) {
                    if (state is! IncomingRequestLoaded) return;

                    if (state.acceptStatus == AcceptRideStatus.success &&
                        state.processingRequest != null) {
                      context.go(
                        tripRoute.route,
                        extra: state.processingRequest,
                      );
                    } else if (state.acceptStatus == AcceptRideStatus.error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.acceptErrorMessage ??
                                'No se pudo aceptar la carrera.',
                          ),
                        ),
                      );
                    }
                  },
                  child: BlocBuilder<IncomingRequestBloc, IncomingRequestState>(
                    builder: (context, state) {
                      if (state is IncomingRequestInitial) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        );
                      }

                      if (state is IncomingRequestLoaded) {
                        final requests = state.requests;

                        if (requests.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.radar, // O un ícono de taxi
                                  size: 80,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay clientes buscando\ntaxi en este momento.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24, top: 8),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];

                            return IncomingRequestTile(
                              incomingRequestEntity: request,
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
    );
  }
}
