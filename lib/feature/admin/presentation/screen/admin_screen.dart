import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/feature/session/presentation/bloc/session/session_bloc.dart';
import '../../domain/entity/admin_driver_entity.dart';
import '../bloc/admin_bloc.dart';
import '../component/delete_driver_confirm_dialog.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => mainServiceLocator<AdminBloc>()..add(AdminLoadRequested()),
      child: const AdminView(),
    );
  }
}

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sessionState = context.read<SessionBloc>().state;
    final viewerRole =
        sessionState is SessionAuthenticated ? sessionState.role : 'driver';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Administración'),
      ),
      body: BlocListener<AdminBloc, AdminState>(
        listenWhen:
            (previous, current) =>
                current.errorMessage != null &&
                current.errorMessage != previous.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colorScheme.error,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: context.appColors.backgroundGradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildSearchBar(context),
                Expanded(
                  child: BlocBuilder<AdminBloc, AdminState>(
                    builder: (context, state) {
                      return _buildBody(context, state, viewerRole);
                    },
                  ),
                ),
                BlocBuilder<AdminBloc, AdminState>(
                  builder: (context, state) {
                    return _buildPaginationBar(context, state);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged:
              (value) => context.read<AdminBloc>().add(
                AdminSearchChanged(query: value),
              ),
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, correo o teléfono',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminState state, String viewerRole) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading && state.drivers.isEmpty) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (state.pageDrivers.isEmpty) {
      return Center(
        child: Text(
          state.searchQuery.isEmpty
              ? 'No hay conductores registrados'
              : 'No se encontraron resultados',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: state.pageDrivers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final driver = state.pageDrivers[index];
        return _buildDriverTile(
          context,
          driver: driver,
          viewerRole: viewerRole,
          isBusy: state.actionUid == driver.uid,
        );
      },
    );
  }

  Widget _buildDriverTile(
    BuildContext context, {
    required AdminDriverEntity driver,
    required String viewerRole,
    required bool isBusy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final canDelete = _canDelete(viewerRole: viewerRole, targetRole: driver.role);
    final canToggleRole = _canToggleRole(
      viewerRole: viewerRole,
      targetRole: driver.role,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
            backgroundImage:
                driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
            child:
                driver.photoUrl == null
                    ? Icon(
                      Icons.person,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName.isEmpty ? 'Sin nombre' : driver.fullName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  driver.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildRoleBadge(context, driver.role),
              ],
            ),
          ),
          if (isBusy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            )
          else ...[
            if (canToggleRole)
              PopupMenuButton<String>(
                tooltip: 'Cambiar rol',
                icon: Icon(Icons.swap_vert_rounded, color: colorScheme.primary),
                onSelected: (newRole) {
                  context.read<AdminBloc>().add(
                    AdminRoleChangeRequested(uid: driver.uid, role: newRole),
                  );
                },
                itemBuilder:
                    (context) =>
                        _rolesFor(driver.role)
                            .map(
                              (role) => PopupMenuItem<String>(
                                value: role,
                                child: Text(_roleLabel(role)),
                              ),
                            )
                            .toList(),
              ),
            if (canDelete)
              IconButton(
                tooltip: 'Eliminar conductor',
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: () async {
                  final confirmed = await DeleteDriverConfirmDialog.show(
                    context: context,
                    driverName:
                        driver.fullName.isEmpty ? driver.email : driver.fullName,
                  );
                  if (confirmed == true && context.mounted) {
                    context.read<AdminBloc>().add(
                      AdminDeleteDriverRequested(uid: driver.uid),
                    );
                  }
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = _roleLabel(role);
    final color = role == 'driver' ? colorScheme.onSurface : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaginationBar(BuildContext context, AdminState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.filteredDrivers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                state.currentPage > 0
                    ? () => context.read<AdminBloc>().add(
                      AdminPageChanged(page: state.currentPage - 1),
                    )
                    : null,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'Página ${state.currentPage + 1} de ${state.totalPages}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          IconButton(
            onPressed:
                state.currentPage < state.totalPages - 1
                    ? () => context.read<AdminBloc>().add(
                      AdminPageChanged(page: state.currentPage + 1),
                    )
                    : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  bool _canDelete({required String viewerRole, required String targetRole}) {
    if (targetRole == 'superuser') return false;
    if (viewerRole == 'superuser') return true;
    if (viewerRole == 'admin') return targetRole == 'driver';
    return false;
  }

  bool _canToggleRole({
    required String viewerRole,
    required String targetRole,
  }) {
    return viewerRole == 'superuser';
  }

  static const List<String> _allRoles = ['driver', 'admin', 'superuser'];

  List<String> _rolesFor(String currentRole) {
    return _allRoles.where((role) => role != currentRole).toList();
  }

  String _roleLabel(String role) {
    return switch (role) {
      'superuser' => 'Superusuario',
      'admin' => 'Administrador',
      _ => 'Conductor',
    };
  }
}
