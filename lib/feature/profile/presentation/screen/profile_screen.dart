import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.pushNamed(settingsRoute.name),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                ),
              );
            }

            if (state.driver == null) {
              return Center(
                child: Text(
                  state.errorMessage ??
                      'No se encontró información del conductor',
                  style: const TextStyle(color: Colors.white70),
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
            _buildProfileHeader(driver),
            const SizedBox(height: 32),
            _buildInfoCard(driver),
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

  Widget _buildProfileHeader(DriverEntity driver) {
    final fullName = '${driver.firstName} ${driver.lastName}'.trim();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
          ),
          child: CircleAvatar(
            radius: 64,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage:
                driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
            child:
                driver.photoUrl == null
                    ? Icon(
                      Icons.person,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    )
                    : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          fullName.isEmpty ? 'Conductor' : fullName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE94560).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: Color(0xFFE94560),
              ),
              const SizedBox(width: 4),
              Text(
                driver.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE94560),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          driver.email,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildInfoCard(DriverEntity driver) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.email_outlined,
              title: 'Correo electrónico',
              value: driver.email,
              isFirst: true,
            ),
            Divider(
              height: 1,
              indent: 60,
              color: Colors.white.withOpacity(0.06),
            ),
            _buildInfoTile(
              icon: Icons.phone_outlined,
              title: 'Teléfono',
              value:
                  driver.phoneNumber.isEmpty
                      ? 'No registrado'
                      : driver.phoneNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 12.0 : 4.0, bottom: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE94560).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFE94560), size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleEntity? vehicle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
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
              color: const Color(0xFFE94560).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_taxi_outlined,
              color: Color(0xFFE94560),
              size: 22,
            ),
          ),
          title: Text(
            vehicle == null ? 'Vehículo' : '${vehicle.brand} ${vehicle.model}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              vehicle == null ? 'No registrado' : vehicle.plate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ),
          trailing:
              vehicle == null
                  ? null
                  : Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.4),
                  ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ConfirmationPopup.show(context: context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.05),
            foregroundColor: const Color(0xFFE94560),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: const Color(0xFFE94560).withOpacity(0.3)),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Color(0xFFE94560)),
              SizedBox(width: 10),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE94560),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
