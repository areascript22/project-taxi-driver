import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/feature/session/presentation/bloc/session/session_bloc.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    _checkIfUserLoggedIn();
  }

  void _checkIfUserLoggedIn() {
    context.read<SessionBloc>().add(SessionCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return const SessionView();
  }
}

class SessionView extends StatelessWidget {
  const SessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state is SessionUnauthenticated) {
            context.goNamed(signInRoute.name);
          }

          if (state is SessionOnboardingRequired) {
            context.goNamed(driverOnboardingRoute.name, extra: state.user);
          }

          if (state is SessionAuthenticated) {
            if (state.activeTrip != null) {
              // Viaje en curso (aceptado antes de un kill de la app) --
              // resume directo en TripScreen en vez de IncomingRequestScreen.
              context.goNamed(tripRoute.name, extra: state.activeTrip);
            } else {
              context.goNamed('booking');
            }
          }
        },
        builder: (context, state) {
          if (state is SessionCheckFailed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No se pudo verificar tu sesión. Revisa tu conexión e '
                      'intenta de nuevo.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SessionBloc>().add(
                        SessionCheckRequested(),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SessionBlocked) {
            return _DriverBlockedView(blockReason: state.blockReason);
          }

          if (state is SessionPendingApproval) {
            return _DriverPendingApprovalView(
              approvalStatus: state.approvalStatus,
              rejectionReason: state.rejectionReason,
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// Se muestra cuando SessionBloc detecta que un admin bloqueó la cuenta (ver
// SessionBlocked en session_state.dart) -- corta el acceso ANTES de llegar a
// Incoming Requests o cualquier otra pantalla autenticada.
class _DriverBlockedView extends StatelessWidget {
  final String? blockReason;

  const _DriverBlockedView({required this.blockReason});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_rounded,
                color: colorScheme.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tu cuenta está bloqueada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Un administrador bloqueó temporalmente tu cuenta y no puedes '
              'recibir carreras mientras tanto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (blockReason != null && blockReason!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.error,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      blockReason!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    () => context.read<SessionBloc>().add(
                      SessionCheckRequested(),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Verificar de nuevo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed:
                  () => context.read<SessionBloc>().add(
                    SessionLogoutRequested(),
                  ),
              child: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Se muestra mientras el conductor no esté aprobado -- recién registrado
// ('pending') o rechazado por un admin ('rejected'). Igual que
// _DriverBlockedView, corta el acceso antes de llegar a cualquier pantalla
// autenticada.
class _DriverPendingApprovalView extends StatelessWidget {
  final String approvalStatus;
  final String? rejectionReason;

  const _DriverPendingApprovalView({
    required this.approvalStatus,
    required this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final isRejected = approvalStatus == 'rejected';
    final color = isRejected ? colorScheme.error : appColors.warning;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected
                    ? Icons.cancel_outlined
                    : Icons.hourglass_top_rounded,
                color: color,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRejected
                  ? 'Tu solicitud fue rechazada'
                  : 'Tu cuenta está en revisión',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRejected
                  ? 'Un administrador revisó tu registro y no fue aprobado.'
                  : 'Un administrador está revisando tu registro. Te '
                      'avisaremos apenas puedas empezar a recibir carreras.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (isRejected &&
                rejectionReason != null &&
                rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rejectionReason!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    () => context.read<SessionBloc>().add(
                      SessionCheckRequested(),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Verificar de nuevo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed:
                  () => context.read<SessionBloc>().add(
                    SessionLogoutRequested(),
                  ),
              child: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
