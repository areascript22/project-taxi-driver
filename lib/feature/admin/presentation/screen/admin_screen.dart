import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/service_locator/main_service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/feature/session/presentation/bloc/session/session_bloc.dart';
import '../../domain/entity/admin_driver_entity.dart';
import '../bloc/admin_bloc.dart';
import '../component/change_role_dialog.dart';

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
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
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

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () => _refresh(context),
      child: _buildListContent(context, state, viewerRole),
    );
  }

  // RefreshIndicator necesita un Future que se resuelva cuando el refresh
  // termine -- como AdminBloc es fire-and-forget (add() no devuelve nada),
  // esperamos a que el stream emita el primer estado con isLoading=false.
  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    bloc.add(AdminLoadRequested());
    return bloc.stream.firstWhere((state) => !state.isLoading);
  }

  Widget _buildListContent(
    BuildContext context,
    AdminState state,
    String viewerRole,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // RefreshIndicator exige un hijo desplazable para poder "jalar" -- los
    // estados de carga/vacío también usan ListView (con un alto generoso)
    // en vez de un Center plano, para que el pull-to-refresh funcione
    // incluso cuando todavía no hay nada que mostrar.
    if (state.isLoading && state.pageDrivers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          ),
        ],
      );
    }

    if (state.pageDrivers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Text(
                state.searchQuery.isEmpty
                    ? 'No hay conductores registrados'
                    : 'No se encontraron resultados',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
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

  Future<void> _openDriverDetail(
    BuildContext context, {
    required AdminDriverEntity driver,
  }) async {
    // DriverDetailScreen maneja aprobar/rechazar/bloquear/desbloquear/
    // eliminar con su propio cubit -- al volver, solo resincronizamos ESE
    // conductor puntualmente (sin perder la página en la que estábamos, a
    // diferencia de un reload completo bajo paginación por cursor).
    await context.push(driverDetailRoute.route, extra: driver);
    if (context.mounted) {
      context.read<AdminBloc>().add(
        AdminDriverRefreshRequested(uid: driver.uid),
      );
    }
  }

  Widget _buildDriverTile(
    BuildContext context, {
    required AdminDriverEntity driver,
    required String viewerRole,
    required bool isBusy,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final canToggleRole = _canToggleRole(
      viewerRole: viewerRole,
      targetRole: driver.role,
    );

    return GestureDetector(
      onTap: () => _openDriverDetail(context, driver: driver),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
              backgroundImage:
                  driver.photoUrl != null
                      ? NetworkImage(driver.photoUrl!)
                      : null,
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildRoleBadge(context, driver.role),
                      _buildApprovalBadge(context, driver),
                    ],
                  ),
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
            else
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'review':
                      await _openDriverDetail(context, driver: driver);
                      break;
                    case 'change_role':
                      final newRole = await ChangeRoleDialog.show(
                        context: context,
                        availableRoles: _rolesFor(driver.role),
                        roleLabel: _roleLabel,
                      );
                      if (newRole != null && context.mounted) {
                        context.read<AdminBloc>().add(
                          AdminRoleChangeRequested(
                            uid: driver.uid,
                            role: newRole,
                          ),
                        );
                      }
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'review',
                        child: Text('Revisar'),
                      ),
                      if (canToggleRole)
                        const PopupMenuItem(
                          value: 'change_role',
                          child: Text('Cambiar rol'),
                        ),
                    ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = _roleLabel(role);
    final color =
        role == 'driver' ? colorScheme.onSurface : colorScheme.primary;

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

  Widget _buildApprovalBadge(BuildContext context, AdminDriverEntity driver) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    final (label, color) =
        driver.isBlocked
            ? ('Bloqueado', colorScheme.error)
            : switch (driver.approvalStatus) {
              'approved' => ('Aprobado', appColors.success),
              'rejected' => ('Rechazado', colorScheme.error),
              _ => ('Pendiente', appColors.warning),
            };

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

    // El total de páginas solo se conoce con certeza en modo búsqueda (ya
    // se cargó todo) o cuando la navegación llegó al final del listado --
    // bajo paginación por cursor no hay forma barata de saber cuántas
    // páginas quedan por delante sin recorrerlas.
    final totalPages = state.totalPages;
    final pageLabel =
        totalPages != null
            ? 'Página ${state.currentPage + 1} de $totalPages'
            : 'Página ${state.currentPage + 1}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                !state.isLoading && state.canGoPrevious
                    ? () => context.read<AdminBloc>().add(
                      AdminPreviousPageRequested(),
                    )
                    : null,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            pageLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          IconButton(
            onPressed:
                !state.isLoading && state.canGoNext
                    ? () => context.read<AdminBloc>().add(
                      AdminNextPageRequested(),
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

  bool _canToggleRole({
    required String viewerRole,
    required String targetRole,
  }) {
    // Ni siquiera un superuser puede cambiarle el rol a otro superuser --
    // misma regla que ya aplica para eliminar/aprobar/bloquear.
    if (targetRole == 'superuser') return false;
    return viewerRole == 'superuser';
  }

  // "superuser" nunca es una opción asignable desde acá -- ni siquiera un
  // superuser puede promover a nadie a superuser (ver
  // DriverAdminService.updateDriverRole en el server, que rechaza ese
  // destino explícitamente).
  static const List<String> _assignableRoles = ['driver', 'admin'];

  List<String> _rolesFor(String currentRole) {
    return _assignableRoles.where((role) => role != currentRole).toList();
  }

  String _roleLabel(String role) {
    return switch (role) {
      'superuser' => 'Superusuario',
      'admin' => 'Administrador',
      _ => 'Conductor',
    };
  }
}
