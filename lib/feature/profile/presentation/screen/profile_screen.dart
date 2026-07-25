import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/domain/entity/user_entity.dart';
import '../../../../shared/feature/session/presentation/bloc/session/session_bloc.dart';
import '../component/confirmation_popup.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileView();
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            if (state is SessionAuthenticated) {
              return _buildProfileContent(context, state.user);
            }
            return const Center(
              child: Text(
                'No se encontró información del usuario',
                style: TextStyle(color: Colors.white70),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserEntity user) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildProfileHeader(user),
            const SizedBox(height: 32),
            _buildInfoCard(user),
            const SizedBox(height: 32),
            _buildSignOutButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity user) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
            boxShadow: [

            ],
          ),
          child: CircleAvatar(
            radius: 64,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child:
                user.photoUrl == null
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
          user.displayName ?? 'Conductor',
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
          child: const Text(
            'Conductor Activo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE94560),
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.email ?? 'Sin correo',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
        ),
      ],
    );
  }

  Widget _buildInfoCard(UserEntity user) {
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
              value: user.email ?? 'No disponible',
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
              value: 'No registrado',
            ),
            Divider(
              height: 1,
              indent: 60,
              color: Colors.white.withOpacity(0.06),
            ),
            _buildInfoTile(
              icon: Icons.car_repair,
              title: 'Vehículo',
              value: 'No registrado',
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
