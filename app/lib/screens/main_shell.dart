library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _Tab('/cases', Icons.chat_bubble_outline, 'Cases'),
    _Tab('/calendar', Icons.calendar_month_outlined, 'Calendar'),
    _Tab('/fees', Icons.currency_rupee, 'Fees'),
    _Tab('/docs', Icons.folder_outlined, 'Docs'),
    _Tab('/profile', Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) {
          navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
        },
        backgroundColor: MunshiColors.ivory,
        indicatorColor: MunshiColors.inkGreen.withValues(alpha: 0.12),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String label;
}
