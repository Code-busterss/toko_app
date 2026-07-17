// lib/shared/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/constants/constants.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith(AppConstants.routeDashboard)) return 0;
    if (location.startsWith(AppConstants.routeProducts)) return 1;
    if (location.startsWith(AppConstants.routeCustomers)) return 2;
    if (location.startsWith(AppConstants.routeOrders)) return 3;
    if (location.startsWith(AppConstants.routeSettings)) return 4;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppConstants.routeDashboard);
        break;
      case 1:
        context.go(AppConstants.routeProducts);
        break;
      case 2:
        context.go(AppConstants.routeCustomers);
        break;
      case 3:
        context.go(AppConstants.routeOrders);
        break;
      case 4:
        context.go(AppConstants.routeSettings);
        break;
    }
  }
}
