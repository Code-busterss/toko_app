// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/dashboard/providers/dashboard_notifier.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardNotifierProvider.notifier).fetchStats();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardNotifierProvider.notifier).fetchStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildMainMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.add_shopping_cart,
                    label: 'Make Order',
                    color: Colors.blue,
                    onTap: () {
                      context.push(AppConstants.routeCreateOrder).then((result) {
                        if (result == true) {
                          ref.read(dashboardNotifierProvider.notifier).fetchStats();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.inventory_2,
                    label: 'Add Product',
                    color: Colors.green,
                    onTap: () {
                      context.push(AppConstants.routeProductAdd);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.person_add,
                    label: 'Add Customer',
                    color: Colors.purple,
                    onTap: () {
                      context.push(AppConstants.routeCustomerAdd).then((result) {
                        if (result == true) {
                          ref.read(dashboardNotifierProvider.notifier).fetchStats();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.payment,
                    label: 'Receive Payment',
                    color: Colors.orange,
                    onTap: () {
                      context.push(AppConstants.routeReceivePayment).then((result) {
                        if (result == true) {
                          ref.read(dashboardNotifierProvider.notifier).fetchStats();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Main Menu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: const Icon(Icons.people, color: Colors.blue),
              ),
              title: const Text('Customers'),
              subtitle: const Text('Manage customers and create bills'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(AppConstants.routeCustomers);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                child: const Icon(Icons.inventory_2, color: Colors.green),
              ),
              title: const Text('Products'),
              subtitle: const Text('Manage inventory and stock'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(AppConstants.routeProducts);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                child: const Icon(Icons.shopping_bag, color: Colors.purple),
              ),
              title: const Text('Orders'),
              subtitle: const Text('View and manage orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(AppConstants.routeOrders);
              },
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                child: const Icon(Icons.bar_chart, color: Colors.orange),
              ),
              title: const Text('Statistics'),
              subtitle: const Text('View sales and business analytics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(AppConstants.routeStats);
              },
            ),
          ],
        ),
      ),
    );
  }
}