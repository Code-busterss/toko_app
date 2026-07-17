// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/features/dashboard/providers/dashboard_notifier.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

import '../../../core/constants/constants.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardNotifierProvider.notifier).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardNotifierProvider);

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
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(dashboardNotifierProvider.notifier).fetchStats();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).fetchStats();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(context, stats),
                const SizedBox(height: 24),
                _buildWeeklySalesChart(context, stats.weeklySales),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentOrders(context, stats.recentOrders),
                const SizedBox(height: 24),
                _buildLowStockProducts(context, stats.lowStockProducts),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildSummaryCard(
          context,
          title: "Today's Sales",
          value: '${AppConstants.currencySymbol} ${stats.todaySales.toStringAsFixed(0)}',
          icon: Icons.today,
          color: Colors.blue,
        ),
        _buildSummaryCard(
          context,
          title: 'Monthly Sales',
          value: '${AppConstants.currencySymbol} ${stats.monthlySales.toStringAsFixed(0)}',
          icon: Icons.calendar_month,
          color: Colors.green,
        ),
        _buildSummaryCard(
          context,
          title: 'Total Orders',
          value: '${stats.totalOrders}',
          icon: Icons.shopping_bag,
          color: Colors.purple,
        ),
        _buildSummaryCard(
          context,
          title: 'Pending Orders',
          value: '${stats.pendingOrders}',
          icon: Icons.pending,
          color: Colors.orange,
        ),
        _buildSummaryCard(
          context,
          title: 'Pending Payments',
          value: '${AppConstants.currencySymbol} ${stats.pendingPayments.toStringAsFixed(0)}',
          icon: Icons.payment,
          color: Colors.red,
        ),
        _buildSummaryCard(
          context,
          title: 'Total Profit',
          value: '${AppConstants.currencySymbol} ${stats.totalProfit.toStringAsFixed(0)}',
          icon: Icons.trending_up,
          color: Colors.teal,
        ),
        _buildSummaryCard(
          context,
          title: 'Total Expenses',
          value: '${AppConstants.currencySymbol} ${stats.totalExpenses.toStringAsFixed(0)}',
          icon: Icons.money_off,
          color: Colors.pink,
        ),
        _buildSummaryCard(
          context,
          title: 'Total Customers',
          value: '${stats.totalCustomers}',
          icon: Icons.people,
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
      }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySalesChart(BuildContext context, List<double> weeklySales) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Sales', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['D-6', 'D-5', 'D-4', 'D-3', 'D-2', 'D-1', 'Today'];
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklySales.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                    onTap: () {},
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

  Widget _buildRecentOrders(BuildContext context, List<Order> orders) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No orders yet'),
                ),
              )
            else
              ...orders.map((order) => _buildOrderItem(context, order)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order) {
    final statusColor = _getOrderStatusColor(order.status);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(Icons.shopping_bag, color: statusColor),
      ),
      title: Text(
        order.invoiceNumber,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        AppConstants.dateFormat.format(order.date),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${AppConstants.currencySymbol} ${order.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              order.status.name.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildLowStockProducts(BuildContext context, List<Product> products) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low Stock Alert', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),
            if (products.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('All products are well stocked'),
                ),
              )
            else
              ...products.map((product) => _buildProductItem(context, product)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product) {
    final stockPercentage = product.minStock > 0
        ? (product.stock / product.minStock).clamp(0.0, 1.0)
        : 1.0;
    final stockColor = stockPercentage < 0.5
        ? Colors.red
        : stockPercentage < 1.0
        ? Colors.orange
        : Colors.green;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: stockColor.withValues(alpha: 0.1),
        child: Icon(Icons.inventory, color: stockColor),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SKU: ${product.sku ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: stockPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(stockColor),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${product.stock} ${product.unit}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: stockColor,
            ),
          ),
          Text(
            'Min: ${product.minStock}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}