import 'package:driver_app/feature/incoming_request/presentation/component/incoming_request_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../bloc/incoming_request_bloc.dart';

class IncomingRequestScreen extends StatelessWidget {
  const IncomingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<IncomingRequestBloc>(),
      child: const IncomingRequestContent(),
    );
  }
}

class IncomingRequestContent extends StatefulWidget {
  const IncomingRequestContent({super.key});

  @override
  State<IncomingRequestContent> createState() => _IncomingRequestContentState();
}

class _IncomingRequestContentState extends State<IncomingRequestContent> {
  @override
  void initState() {
    super.initState();
    context.read<IncomingRequestBloc>().add(StartListeningRequests());
  }

  @override
  void dispose() {
    // context.read<IncomingRequestBloc>().add(StopListeningRequests());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Peticiones Entrantes',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: BlocListener<IncomingRequestBloc, IncomingRequestState>(
          listenWhen: (previous, current) =>
              previous is IncomingRequestLoaded &&
              current is IncomingRequestLoaded &&
              previous.acceptStatus != current.acceptStatus,
          listener: (context, state) {
            if (state is! IncomingRequestLoaded) return;

            if (state.acceptStatus == AcceptRideStatus.success &&
                state.processingRequest != null) {
              context.go(tripRoute.route, extra: state.processingRequest);
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
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE94560)),
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
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay clientes buscando\ntaxi en este momento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
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

                  return IncomingRequestTile(incomingRequestEntity: request);
                },
              );
            }

            return const SizedBox.shrink();
          },
          ),
        ),
      ),
    );
  }
}
