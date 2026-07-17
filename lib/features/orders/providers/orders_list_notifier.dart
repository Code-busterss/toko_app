// lib/features/orders/providers/orders_list_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/orders/models/order_with_customer.dart';
import 'package:toko_app/shared/models/app_enums.dart';

enum OrderFilterStatus { all, pending, paid, partial }

class OrderListFilter {
  final OrderFilterStatus status;
  final String searchQuery;

  const OrderListFilter({
    this.status = OrderFilterStatus.all,
    this.searchQuery = '',
  });

  OrderListFilter copyWith({
    OrderFilterStatus? status,
    String? searchQuery,
  }) {
    return OrderListFilter(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OrderStats {
  final int todayOrdersCount;
  final double todayTotalAmount;
  final int totalPending;
  final double totalPendingAmount;

  const OrderStats({
    required this.todayOrdersCount,
    required this.todayTotalAmount,
    required this.totalPending,
    required this.totalPendingAmount,
  });

  static const empty = OrderStats(
    todayOrdersCount: 0,
    todayTotalAmount: 0,
    totalPending: 0,
    totalPendingAmount: 0,
  );
}

class OrdersListState {
  final AsyncValue<List<OrderWithCustomer>> orders;
  final AsyncValue<OrderStats> stats;
  final OrderListFilter filter;
  final String? actionMessage;
  final bool isActionError;
  final int? processingOrderId;

  const OrdersListState({
    this.orders = const AsyncLoading(),
    this.stats = const AsyncLoading(),
    this.filter = const OrderListFilter(),
    this.actionMessage,
    this.isActionError = false,
    this.processingOrderId,
  });

  OrdersListState copyWith({
    AsyncValue<List<OrderWithCustomer>>? orders,
    AsyncValue<OrderStats>? stats,
    OrderListFilter? filter,
    String? actionMessage,
    bool? isActionError,
    int? processingOrderId,
    bool clearMessage = false,
    bool clearProcessing = false,
  }) {
    return OrdersListState(
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
      filter: filter ?? this.filter,
      actionMessage: clearMessage ? null : (actionMessage ?? this.actionMessage),
      isActionError: isActionError ?? this.isActionError,
      processingOrderId:
          clearProcessing ? null : (processingOrderId ?? this.processingOrderId),
    );
  }
}

class OrdersListNotifier extends Notifier<OrdersListState> {
  @override
  OrdersListState build() {
    _fetchAll();
    _fetchStats();
    return const OrdersListState();
  }

  Future<void> _fetchAll() async {
    try {
      final db = await DatabaseService.instance.database;

      // Fetch all orders with customer info
      final orderResults = await db.rawQuery('''
        SELECT o.*, c.shopName as customerName, c.phone as customerPhone
        FROM orders o
        LEFT JOIN customers c ON o.customerId = c.id
        WHERE o.status != ?
        ORDER BY o.date DESC
      ''', [OrderStatus.cancelled.index]);

      final allOrders = orderResults.map((row) {
        final order = Order.fromMap(row);
        return OrderWithCustomer(
          order: order,
          customerName: row['customerName'] as String? ?? 'Unknown',
          customerPhone: row['customerPhone'] as String? ?? '',
        );
      }).toList();

      // Apply filters
      final filter = state.filter;
      List<OrderWithCustomer> filtered = allOrders;

      // Status filter
      if (filter.status != OrderFilterStatus.all) {
        filtered = filtered.where((o) {
          switch (filter.status) {
            case OrderFilterStatus.pending:
              return o.order.status == OrderStatus.pending;
            case OrderFilterStatus.paid:
              return o.paymentStatus == PaymentStatus.paid;
            case OrderFilterStatus.partial:
              return o.paymentStatus == PaymentStatus.partial ||
                  o.paymentStatus == PaymentStatus.unpaid;
            default:
              return true;
          }
        }).toList();
      }

      // Search filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        filtered = filtered.where((o) {
          return o.order.invoiceNumber.toLowerCase().contains(query) ||
              o.customerName.toLowerCase().contains(query);
        }).toList();
      }

      state = state.copyWith(
        orders: AsyncData(filtered),
      );
    } catch (e, stackTrace) {
      state = state.copyWith(
        orders: AsyncError(e, stackTrace),
      );
    }
  }

  Future<void> _fetchStats() async {
    try {
      final db = await DatabaseService.instance.database;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Today's orders
      final todayResult = await db.rawQuery('''
        SELECT COUNT(*) as count, COALESCE(SUM(totalAmount), 0) as total
        FROM orders
        WHERE date >= ? AND date < ? AND status != ?
      ''', [
        todayStart.toIso8601String(),
        todayEnd.toIso8601String(),
        OrderStatus.cancelled.index,
      ]);

      final todayCount = (todayResult.first['count'] as int?) ?? 0;
      final todayTotal = (todayResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Pending orders (unpaid or partial)
      final pendingResult = await db.rawQuery('''
        SELECT COUNT(*) as count, COALESCE(SUM(totalAmount - paidAmount), 0) as total
        FROM orders
        WHERE status != ? AND totalAmount > paidAmount
      ''', [OrderStatus.cancelled.index]);

      final pendingCount = (pendingResult.first['count'] as int?) ?? 0;
      final pendingTotal =
          (pendingResult.first['total'] as num?)?.toDouble() ?? 0.0;

      state = state.copyWith(
        stats: AsyncData(OrderStats(
          todayOrdersCount: todayCount,
          todayTotalAmount: todayTotal,
          totalPending: pendingCount,
          totalPendingAmount: pendingTotal,
        )),
      );
    } catch (e, stackTrace) {
      state = state.copyWith(
        stats: AsyncError(e, stackTrace),
      );
    }
  }

  void setFilter(OrderFilterStatus status) {
    state = state.copyWith(
      filter: state.filter.copyWith(status: status),
    );
    _fetchAll();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      filter: state.filter.copyWith(searchQuery: query),
    );
    _fetchAll();
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  Future<void> refresh() async {
    await Future.wait([_fetchAll(), _fetchStats()]);
  }

  Future<bool> markAsPaid(OrderWithCustomer orderWithCustomer) async {
    final order = orderWithCustomer.order;
    if (order.paidAmount >= order.totalAmount) {
      state = state.copyWith(
        actionMessage: 'Order is already fully paid',
        isActionError: true,
      );
      return false;
    }

    state = state.copyWith(processingOrderId: order.id);

    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'orders',
        {
          'paidAmount': order.totalAmount,
          'status': OrderStatus.completed.index,
        },
        where: 'id = ?',
        whereArgs: [order.id],
      );

      state = state.copyWith(
        actionMessage: 'Order marked as paid',
        isActionError: false,
        clearProcessing: true,
      );

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(
        actionMessage: 'Failed to mark as paid: $e',
        isActionError: true,
        clearProcessing: true,
      );
      return false;
    }
  }

  Future<bool> deleteOrder(int orderId) async {
    state = state.copyWith(processingOrderId: orderId);

    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'orders',
        {'status': OrderStatus.cancelled.index},
        where: 'id = ?',
        whereArgs: [orderId],
      );

      state = state.copyWith(
        actionMessage: 'Order cancelled',
        isActionError: false,
        clearProcessing: true,
      );

      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(
        actionMessage: 'Failed to cancel order: $e',
        isActionError: true,
        clearProcessing: true,
      );
      return false;
    }
  }
}

final ordersListNotifierProvider =
    NotifierProvider<OrdersListNotifier, OrdersListState>(
  OrdersListNotifier.new,
);
