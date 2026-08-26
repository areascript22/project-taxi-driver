import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../feature/session/presentation/bloc/session/session_bloc.dart';

// Índices de StatefulShellBranch en app_routing.dart: 0=Booking, 1=Admin,
// 2=Profile. El branch Admin siempre existe en el router, pero su ítem en
// este nav bar solo se muestra si el rol del driver lo permite.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionBloc>().state;
    final role = sessionState is SessionAuthenticated ? sessionState.role : 'driver';
    final showAdminTab = role == 'admin' || role == 'superuser';

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigationBar(context, showAdminTab),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, bool showAdminTab) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.35);

    // Índice de branch (en el router) correspondiente a cada ítem visible,
    // en el mismo orden en que se muestran los íconos.
    final branchIndices = showAdminTab ? const [0, 1, 2] : const [0, 2];
    final selectedItemIndex = branchIndices.indexOf(navigationShell.currentIndex);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BottomNavigationBar(
        backgroundColor: colorScheme.surface,
        currentIndex: selectedItemIndex < 0 ? 0 : selectedItemIndex,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          _buildSvgNavItem(
            icon: 'assets/icons/svg/location.svg',
            label: 'Pedir',
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          if (showAdminTab)
            _buildIconDataNavItem(
              icon: Icons.admin_panel_settings_outlined,
              activeIcon: Icons.admin_panel_settings,
              label: 'Admin',
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
            ),
          _buildSvgNavItem(
            icon: 'assets/icons/svg/profile.svg',
            label: 'Perfil',
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
        ],
        onTap: (int index) => _onTap(branchIndices[index]),
      ),
    );
  }

  BottomNavigationBarItem _buildSvgNavItem({
    required String icon,
    required String label,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        icon,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(unselectedColor, BlendMode.srcIn),
      ),
      activeIcon: SvgPicture.asset(
        icon,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _buildIconDataNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 24, color: unselectedColor),
      activeIcon: Icon(activeIcon, size: 24, color: selectedColor),
      label: label,
    );
  }

  void _onTap(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}
