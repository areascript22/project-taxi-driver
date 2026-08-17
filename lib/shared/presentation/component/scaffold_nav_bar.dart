import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigationBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.35);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BottomNavigationBar(
        backgroundColor: colorScheme.surface,
        currentIndex: navigationShell.currentIndex,
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
          _buildNavItem(
            icon: 'assets/icons/svg/location.svg',
            label: 'Pedir',
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          _buildNavItem(
            icon: 'assets/icons/svg/profile.svg',
            label: 'Perfil',
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
        ],
        onTap: (int index) => _onTap(index),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
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

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
