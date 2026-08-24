import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/feature/session/presentation/bloc/session/session_bloc.dart';
import '../../../driver_profile/domain/entity/driver_entity.dart';
import '../../../driver_profile/domain/entity/vehicle_entity.dart';
import '../bloc/profile_bloc.dart';
import '../component/confirmation_popup.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.read<SessionBloc>().state;
    final driverId =
        sessionState is SessionAuthenticated ? sessionState.user.id : null;

    return BlocProvider(
      create:
          (_) =>
              mainServiceLocator<ProfileBloc>()
                ..add(ProfileLoadRequested(driverId: driverId ?? '')),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(settingsRoute.name),
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
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            if (state.driver == null) {
              return Center(
                child: Text(
                  state.errorMessage ??
                      'No se encontró información del conductor',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              );
            }

            return _buildProfileContent(context, state.driver!, state.vehicle);
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    DriverEntity driver,
    VehicleEntity? vehicle,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProfileHeader(context, driver),
            const SizedBox(height: 32),
            _buildInfoCard(context, driver),
            const SizedBox(height: 20),
            _buildVehicleCard(context, vehicle),
            const SizedBox(height: 32),
            _buildSignOutButton(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, DriverEntity driver) {
    final colorScheme = Theme.of(context).colorScheme;
    final fullName = '${driver.firstName} ${driver.lastName}'.trim();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              width: 3,
            ),
          ),
          child: CircleAvatar(
            radius: 64,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
            backgroundImage:
                driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
            child:
                driver.photoUrl == null
                    ? Icon(
                      Icons.person,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    )
                    : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          fullName.isEmpty ? 'Conductor' : fullName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                driver.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          driver.email,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, DriverEntity driver) {
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
            _buildInfoTile(
              context,
              icon: Icons.email_outlined,
              title: 'Correo electrónico',
              value: driver.email,
              isFirst: true,
            ),
            Divider(
              height: 1,
              indent: 60,
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
            _buildInfoTile(
              context,
              icon: Icons.phone_outlined,
              title: 'Teléfono',
              value:
                  driver.phoneNumber.isEmpty
                      ? 'No registrado'
                      : driver.phoneNumber,
            ),
            Divider(
              height: 1,
              indent: 60,
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
            _buildInfoTile(
              context,
              icon:
                  driver.role == 'admin'
                      ? Icons.admin_panel_settings_outlined
                      : Icons.local_taxi_outlined,
              title: 'Rol',
              value: driver.role == 'admin' ? 'Administrador' : 'Conductor',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isFirst = false,
  }) {
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

  Widget _buildVehicleCard(BuildContext context, VehicleEntity? vehicle) {
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
        child: ListTile(
          onTap:
              vehicle == null
                  ? null
                  : () =>
                      context.pushNamed(vehicleInfoRoute.name, extra: vehicle),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_taxi_outlined,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          title: Text(
            vehicle == null ? 'Vehículo' : '${vehicle.brand} ${vehicle.model}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              vehicle == null ? 'No registrado' : vehicle.plate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              ),
            ),
          ),
          trailing:
              vehicle == null
                  ? null
                  : Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ConfirmationPopup.show(context: context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.05),
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
