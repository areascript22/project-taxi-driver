import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entity/admin_driver_entity.dart';

class DriverDetailScreen extends StatelessWidget {
  final AdminDriverEntity driver;

  const DriverDetailScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle del conductor',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                const SizedBox(height: 32),
                _buildDriverInfoCard(context),
                const SizedBox(height: 24),
                _buildVehicleSection(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(BuildContext context) {
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
              title: 'Correo',
              value: driver.email,
              isFirst: true,
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.phone_outlined,
              title: 'Teléfono',
              value: driver.phoneNumber,
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.star_outline_rounded,
              title: 'Calificación',
              value: driver.rating.toStringAsFixed(1),
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.notifications_outlined,
              title: 'Token de notificaciones',
              value:
                  driver.fcmToken.isEmpty ? 'No registrado' : driver.fcmToken,
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.event_available_outlined,
              title: 'Registrado el',
              value: _formatDate(driver.createdAt),
            ),
            _divider(colorScheme),
            _InfoTile(
              icon: Icons.update_outlined,
              title: 'Última actualización',
              value: _formatDate(driver.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vehicle = driver.vehicle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehículo',
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
                'Este conductor no tiene un vehículo registrado',
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
                    title: 'Marca',
                    value: vehicle.brand,
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.directions_car_filled_outlined,
                    title: 'Modelo',
                    value: vehicle.model,
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Año',
                    value: '${vehicle.year}',
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.palette_outlined,
                    title: 'Color',
                    value: vehicle.color,
                  ),
                  _divider(colorScheme),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    title: 'Número de matrícula',
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin datos';
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
          driver.fullName.isEmpty ? 'Sin nombre' : driver.fullName,
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
    final label = switch (role) {
      'superuser' => 'Superusuario',
      'admin' => 'Administrador',
      _ => 'Conductor',
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

class _VerificationBadge extends StatelessWidget {
  final String status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    final (label, color) = switch (status) {
      'approved' => ('Aprobado', appColors.success),
      'rejected' => ('Rechazado', colorScheme.error),
      _ => ('En revisión', appColors.warning),
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
            value.isEmpty ? 'Sin datos' : value,
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
