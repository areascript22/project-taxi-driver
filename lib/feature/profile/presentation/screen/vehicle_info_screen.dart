import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../driver_profile/domain/entity/vehicle_entity.dart';

class VehicleInfoScreen extends StatelessWidget {
  final VehicleEntity vehicle;

  const VehicleInfoScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi vehículo',
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
                _VehicleHeader(vehicle: vehicle),
                const SizedBox(height: 32),
                _buildInfoCard(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
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
              icon: Icons.branding_watermark_outlined,
              title: 'Marca',
              value: vehicle.brand,
              isFirst: true,
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
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 60,
      color: colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final VehicleEntity vehicle;

  const _VehicleHeader({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.15),
              width: 3,
            ),
          ),
          child: Icon(
            Icons.local_taxi_rounded,
            size: 48,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          vehicle.plate,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        _VerificationBadge(status: vehicle.verificationStatus),
      ],
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
      'approved' => ('Vehículo aprobado', appColors.success),
      'rejected' => ('Vehículo rechazado', colorScheme.error),
      _ => ('En revisión', appColors.warning),
    };

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
            value,
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
