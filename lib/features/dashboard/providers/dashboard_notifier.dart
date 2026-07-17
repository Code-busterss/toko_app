// lib/features/dashboard/providers/dashboard_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class DashboardStats {
  final double todaySales;
  final double monthlySales;
  final int totalOrders;
  final int pendingOrders;
  final double pendingPayments;
  final double totalProfit;
  final double totalExpenses;
  final int totalCustomers;
  final List<double> weeklySales;
  final List<Order> recentOrders;
  final List<Product> lowStockProducts;

  DashboardStats({
    required this.todaySales,
    required this.monthlySales,
    required this.totalOrders,
    required this.pendingOrders,
    required this.pendingPayments,
    required this.totalProfit,
    required this.totalExpenses,
    required this.totalCustomers,
    required this.weeklySales,
    required this.recentOrders,
    required this.lowStockProducts,
  });
}

class DashboardNotifier extends Notifier<AsyncValue<DashboardStats>> {
  @override
  AsyncValue<DashboardStats> build() {
    fetchStats();
    return const AsyncLoading();
  }

  Future<void> fetchStats() async {
    state = const AsyncLoading();
    try {
      final db = await DatabaseService.instance.database;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Today's Sales
      final todaySalesResult = await db.rawQuery(
        'SELECT SUM(totalAmount) as total FROM orders WHERE date >= ? AND date < ? AND status != ?',
        [todayStart.toIso8601String(), todayEnd.toIso8601String(), OrderStatus.cancelled.index],
      );
      final todaySales = (todaySalesResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Monthly Sales
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 1);
      final monthlySalesResult = await db.rawQuery(
        'SELECT SUM(totalAmount) as total FROM orders WHERE date >= ? AND date < ? AND status != ?',
        [monthStart.toIso8601String(), monthEnd.toIso8601String(), OrderStatus.cancelled.index],
      );
      final monthlySales = (monthlySalesResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Total Orders
      final totalOrdersResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE status != ?',
        [OrderStatus.cancelled.index],
      );
      final totalOrders = (totalOrdersResult.first['count'] as int?) ?? 0;

      // Pending Orders
      final pendingOrdersResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM orders WHERE status = ?',
        [OrderStatus.pending.index],
      );
      final pendingOrders = (pendingOrdersResult.first['count'] as int?) ?? 0;

      // Pending Payments
      final pendingPaymentsResult = await db.rawQuery(
        'SELECT SUM(totalAmount - paidAmount) as total FROM orders WHERE status != ? AND totalAmount > paidAmount',
        [OrderStatus.cancelled.index],
      );
      final pendingPayments = (pendingPaymentsResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Total Profit (Sales - Purchases - Expenses)
      final salesResult = await db.rawQuery(
        'SELECT SUM(totalAmount) as total FROM orders WHERE status != ?',
        [OrderStatus.cancelled.index],
      );
      final totalSalesAmount = (salesResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final purchasesResult = await db.rawQuery(
        'SELECT SUM(totalAmount) as total FROM purchases',
      );
      final totalPurchasesAmount = (purchasesResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final expensesResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM expenses',
      );
      final totalExpenses = (expensesResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final totalProfit = totalSalesAmount - totalPurchasesAmount - totalExpenses;

      // Total Customers
      final totalCustomersResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM customers',
      );
      final totalCustomers = (totalCustomersResult.first['count'] as int?) ?? 0;

      // Weekly Sales (last 7 days)
      final weeklySales = <double>[];
      for (int i = 6; i >= 0; i--) {
        final dayStart = todayStart.subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        final result = await db.rawQuery(
          'SELECT SUM(totalAmount) as total FROM orders WHERE date >= ? AND date < ? AND status != ?',
          [dayStart.toIso8601String(), dayEnd.toIso8601String(), OrderStatus.cancelled.index],
        );
        weeklySales.add((result.first['total'] as num?)?.toDouble() ?? 0.0);
      }

      // Recent Orders (last 5)
      final recentOrdersResult = await db.rawQuery(
        'SELECT * FROM orders WHERE status != ? ORDER BY date DESC LIMIT 5',
        [OrderStatus.cancelled.index],
      );
      final recentOrders = recentOrdersResult.map((map) => Order.fromMap(map)).toList();

      // Low Stock Products
      final lowStockResult = await db.rawQuery(
        'SELECT * FROM products WHERE stock <= minStock ORDER BY stock ASC LIMIT 10',
      );
      final lowStockProducts = lowStockResult.map((map) => Product.fromMap(map)).toList();

      state = AsyncData(DashboardStats(
        todaySales: todaySales,
        monthlySales: monthlySales,
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        pendingPayments: pendingPayments,
        totalProfit: totalProfit,
        totalExpenses: totalExpenses,
        totalCustomers: totalCustomers,
        weeklySales: weeklySales,
        recentOrders: recentOrders,
        lowStockProducts: lowStockProducts,
      ));
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}

final dashboardNotifierProvider = NotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>(
  DashboardNotifier.new,
);