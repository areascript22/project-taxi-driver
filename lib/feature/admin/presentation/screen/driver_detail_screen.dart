import 'package:driver_app/shared/presentation/failure_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/feature/session/presentation/bloc/session/session_bloc.dart';
import '../../../../shared/presentation/component/app_toast.dart';
import '../../domain/entity/admin_driver_entity.dart';
import '../../domain/repository/admin_repository.dart';
import '../bloc/driver_detail_cubit.dart';
import '../component/delete_driver_confirm_dialog.dart';
import '../component/reason_input_dialog.dart';
import '../component/unblock_driver_confirm_dialog.dart';

class DriverDetailScreen extends StatelessWidget {
  final AdminDriverEntity driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => DriverDetailCubit(
            adminRepository: mainServiceLocator<AdminRepository>(),
            driver: driver,
          ),
      child: const _DriverDetailView(),
    );
  }
}

class _DriverDetailView extends StatelessWidget {
  const _DriverDetailView();

  // Misma jerarquía que ya aplica en el server (DriverAdminService):
  // nadie -- ni otro superuser -- puede actuar sobre un superuser, y un
  // admin normal no puede actuar sobre otro admin. Se usa tanto para el
  // ícono de eliminar como para decidir si se muestra la barra de acciones
  // (aprobar/rechazar/bloquear/desbloquear) de más abajo.
  bool _canModerate({required String viewerRole, required String targetRole}) {
    if (targetRole == 'superuser') return false;
    if (viewerRole == 'superuser') return true;
    if (viewerRole == 'admin') return targetRole == 'driver';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessionState = context.read<SessionBloc>().state;
    final viewerRole =
        sessionState is SessionAuthenticated ? sessionState.role : 'driver';

    return BlocConsumer<DriverDetailCubit, DriverDetailState>(
      listenWhen:
          (previous, current) =>
              (current.errorCode != null &&
                  current.errorCode != previous.errorCode) ||
              current.wasDeleted != previous.wasDeleted,
      listener: (context, state) {
        if (state.errorCode != null) {
          AppToast.error(context, message: context.failureText(state.errorCode!));
        }
        if (state.wasDeleted) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final driver = state.driver;
        final canModerate = _canModerate(
          viewerRole: viewerRole,
          targetRole: driver.role,
        );
        final cubit = context.read<DriverDetailCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context).adminDriverDetailTitle,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              if (canModerate)
                IconButton(
                  tooltip: AppLocalizations.of(context).adminDeleteDriver,
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed:
                      state.isProcessing
                          ? null
                          : () async {
                            final confirmed = await DeleteDriverConfirmDialog.show(
                              context: context,
                              driverName:
                                  driver.fullName.isEmpty
                                      ? driver.email
                                      : driver.fullName,
                            );
                            if (confirmed == true && context.mounted) {
                              cubit.delete();
                            }
                          },
                ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: context.appColors.backgroundGradient,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _DriverHeader(driver: driver),
                    const SizedBox(height: 20),
                    _ApprovalStatusBanner(driver: driver),
                    const SizedBox(height: 24),
                    _buildDriverInfoCard(context, driver),
                    const SizedBox(height: 24),
                    _buildVehicleSection(context, driver),
                    const SizedBox(height: 28),
                    if (canModerate)
                      _buildActionBar(
                        context,
                        driver: driver,
                        isProcessing: state.isProcessing,
                        cubit: cubit,
                      )
                    else
                      _buildNoPermissionNotice(context),
                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Se muestra en vez de la barra de acciones cuando el conductor abierto es
  // de un nivel igual o superior al del admin que está mirando (otro admin,
  // o un superuser) -- explica por qué no hay botones en vez de dejar la
  // sección vacía sin explicación.
  Widget _buildNoPermissionNotice(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).adminNoModeratePermission,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context, {
    required AdminDriverEntity driver,
    required bool isProcessing,
    required DriverDetailCubit cubit,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Widget> buttons;
    if (driver.isBlocked) {
      buttons = [
        Expanded(
          child: FilledButton(
            onPressed:
                isProcessing
                    ? null
                    : () async {
                      final confirmed = await UnblockDriverConfirmDialog.show(
                        context: context,
                        driverName:
                            driver.fullName.isEmpty
                                ? driver.email
                                : driver.fullName,
                      );
                      if (confirmed == true) cubit.unblock();
                    },
            child: Text(AppLocalizations.of(context).adminUnblock),
          ),
        ),
      ];
    } else if (driver.approvalStatus == 'approved') {
      buttons = [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
            onPressed:
                isProcessing
                    ? null
                    : () async {
                      final reason = await ReasonInputDialog.show(
                        context: context,
                        title: AppLocalizations.of(context).adminBlockDriver,
                        description:
                            AppLocalizations.of(context).adminBlockReasonHelp,
                        confirmLabel: AppLocalizations.of(context).adminBlock,
                      );
                      if (reason != null) cubit.block(reason: reason);
                    },
            child: Text(AppLocalizations.of(context).adminBlock),
          ),
        ),
      ];
    } else {
      final isPending = driver.approvalStatus == 'pending';
      buttons = [
        if (isPending)
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
              ),
              onPressed:
                  isProcessing
                      ? null
                      : () async {
                        final reason = await ReasonInputDialog.show(
                          context: context,
                          title: AppLocalizations.of(context).adminRejectDriver,
                          description:
                              AppLocalizations.of(context).adminRejectReasonHelp,
                          confirmLabel: AppLocalizations.of(context).adminReject,
                        );
                        if (reason != null) cubit.reject(reason: reason);
                      },
              child: Text(AppLocalizations.of(context).adminReject),
            ),
          ),
        if (isPending) const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isProcessing ? null : cubit.approve,
            child: Text(AppLocalizations.of(context).adminApprove),
          ),
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),
          Row(children: buttons),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard(BuildContext context, AdminDriverEntity driver) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.email_outlined,
              title: AppLocalizations.of(context).adminEmailLabel,
              value: driver.email,
              isFirst: true,
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.phone_outlined,
              title: AppLocalizations.of(context).commonPhone,
              value: driver.phoneNumber,
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.star_outline_rounded,
              title: AppLocalizations.of(context).adminRating,
              value: driver.rating.toStringAsFixed(1),
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.notifications_outlined,
              title: AppLocalizations.of(context).adminFcmToken,
              value:
                  driver.fcmToken.isEmpty
                      ? AppLocalizations.of(context).commonNotProvided
                      : driver.fcmToken,
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.event_available_outlined,
              title: AppLocalizations.of(context).adminRegisteredAt,
              value: _formatDate(
                l10n: AppLocalizations.of(context),
                date: driver.createdAt,
              ),
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.update_outlined,
              title: AppLocalizations.of(context).adminUpdatedAt,
              value: _formatDate(
                l10n: AppLocalizations.of(context),
                date: driver.updatedAt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection(BuildContext context, AdminDriverEntity driver) {
    final colorScheme = Theme.of(context).colorScheme;
    final vehicle = driver.vehicle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).adminVehicleSection,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (vehicle == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).adminNoVehicle,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          vehicle.plate,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: 1.2,
                          ),
                        ),
                        _VerificationBadge(status: vehicle.verificationStatus),
                      ],
                    ),
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.branding_watermark_outlined,
                    title: AppLocalizations.of(context).vehicleBrand,
                    value: vehicle.brand,
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.directions_car_filled_outlined,
                    title: AppLocalizations.of(context).vehicleModel,
                    value: vehicle.model,
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    title: AppLocalizations.of(context).vehicleYear,
                    value: '${vehicle.year}',
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.palette_outlined,
                    title: AppLocalizations.of(context).vehicleColor,
                    value: vehicle.color,
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    title: AppLocalizations.of(context).vehicleRegistrationNumber,
                    value: vehicle.registrationNumber,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 60,
      color: colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }

  // Recibe l10n por parámetro (no BuildContext) porque es un helper puro de
  // formato: así no depende del árbol de widgets y se puede testear directo.
  String _formatDate({required AppLocalizations l10n, DateTime? date}) {
    if (date == null) return l10n.commonNoData;
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _DriverHeader extends StatelessWidget {
  final AdminDriverEntity driver;

  const _DriverHeader({required this.driver});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
          backgroundImage:
              driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
          child:
              driver.photoUrl == null
                  ? Icon(
                    Icons.person,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  )
                  : null,
        ),
        const SizedBox(height: 16),
        Text(
          driver.fullName.isEmpty
              ? AppLocalizations.of(context).commonNoName
              : driver.fullName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        _RoleBadge(role: driver.role),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // 'superuser'/'admin' son valores del backend y no se traducen.
    final label = switch (role) {
      'superuser' => l10n.roleSuperuser,
      'admin' => l10n.roleAdmin,
      _ => l10n.roleDriver,
    };
    final color =
        role == 'driver' ? colorScheme.onSurface : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Banner con el estado de autorización del conductor (pendiente/rechazado/
// bloqueado/activo) + el motivo cuando aplica. Es lo primero que ve el admin
// al abrir el detalle, antes de decidir qué acción tomar abajo.
class _ApprovalStatusBanner extends StatelessWidget {
  final AdminDriverEntity driver;

  const _ApprovalStatusBanner({required this.driver});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context);

    final String label;
    final String? description;
    final Color color;

    if (driver.isBlocked) {
      label = l10n.adminAccountBlocked;
      description =
          (driver.blockReason?.isNotEmpty ?? false)
              ? l10n.commonReasonWithValue(driver.blockReason!)
              : null;
      color = colorScheme.error;
    } else {
      switch (driver.approvalStatus) {
        case 'approved':
          label = l10n.adminDriverActive;
          description = null;
          color = appColors.success;
          break;
        case 'rejected':
          label = l10n.adminApplicationRejected;
          description =
              (driver.rejectionReason?.isNotEmpty ?? false)
                  ? l10n.commonReasonWithValue(driver.rejectionReason!)
                  : null;
          color = colorScheme.error;
          break;
        default:
          label = l10n.adminPendingApproval;
          description = l10n.adminPendingApprovalBody;
          color = appColors.warning;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final String status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final l10n = AppLocalizations.of(context);

    final (label, color) = switch (status) {
      'approved' => (l10n.adminStatusApproved, appColors.success),
      'rejected' => (l10n.adminStatusRejected, colorScheme.error),
      _ => (l10n.vehicleStatusInReview, appColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isFirst;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 12.0 : 4.0, bottom: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value.isEmpty
                ? AppLocalizations.of(context).commonNoData
                : value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
