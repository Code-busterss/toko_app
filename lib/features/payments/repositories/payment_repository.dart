// lib/features/payments/repositories/payment_repository.dart
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/payments/models/payment_model.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class LedgerEntry {
  final DateTime date;
  final String type; // 'order' or 'payment'
  final String description;
  final String reference;
  final double debit;
  final double credit;
  final double runningBalance;
  final String? semanticType; // 'full', 'partial', 'advance'
  final String? notes;

  LedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.semanticType,
    this.notes,
  });

  bool get isOrder => type == 'order';
  bool get isPayment => type == 'payment';
}

class PaymentRepository {
  Future<void> recordPayment(Payment payment) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      // 1. Insert payment row
      await txn.insert('payments', payment.toMap());

      // 2. Update customer remainingBalance
      final customers = await txn.query('customers',
          where: 'id = ?', whereArgs: [payment.customerId]);
      if (customers.isNotEmpty) {
        final current =
            customers.first['remainingBalance'] as double? ?? 0.0;
        final newBalance = (current - payment.amount).clamp(0.0, double.infinity);
        await txn.update('customers', {'remainingBalance': newBalance},
            where: 'id = ?', whereArgs: [payment.customerId]);
      }

      // 3. If linked to an order, update order paidAmount
      if (payment.orderId != null) {
        final orders = await txn.query('orders',
            where: 'id = ?', whereArgs: [payment.orderId]);
        if (orders.isNotEmpty) {
          final currentPaid =
              orders.first['paidAmount'] as double? ?? 0.0;
          final total = orders.first['totalAmount'] as double? ?? 0.0;
          final newPaid = (currentPaid + payment.amount).clamp(0.0, total);
          await txn.update('orders', {'paidAmount': newPaid},
              where: 'id = ?', whereArgs: [payment.orderId]);
        }
      }
    });
  }

  /// Atomic: inserts the payment, decrements the customer's previousBalance,
  /// and (when an orderId is provided) updates the order's paidAmount and
  /// auto-completes the order if fully paid. All three steps run inside a
  /// single sqflite transaction so a partial failure cannot corrupt data.
  Future<int> recordPaymentAtomic(
    Payment payment, {
    int? orderId,
    double? newOrderPaidAmount,
  }) async {
    final db = await DatabaseService.instance.database;
    int paymentId = 0;

    await db.transaction((txn) async {
      // 1. Insert the payment row.
      paymentId = await txn.insert('payments', payment.toMap());

      // 2. Reduce customer's outstanding balance.
      await txn.rawUpdate(
        'UPDATE customers SET previousBalance = previousBalance - ? WHERE id = ?',
        [payment.amount, payment.customerId],
      );

      // 3. If tied to an order, update its paidAmount + status.
      if (orderId != null && newOrderPaidAmount != null) {
        final totalRow = await txn.rawQuery(
          'SELECT totalAmount FROM orders WHERE id = ?',
          [orderId],
        );
        final total = totalRow.isEmpty
            ? 0.0
            : (totalRow.first['totalAmount'] as num?)?.toDouble() ?? 0.0;

        final newStatus = newOrderPaidAmount >= total
            ? OrderStatus.completed.index
            : OrderStatus.pending.index;
        await txn.rawUpdate(
          'UPDATE orders SET paidAmount = ?, status = ? WHERE id = ?',
          [newOrderPaidAmount, newStatus, orderId],
        );
      }
    });

    return paymentId;
  }

  /// Atomic full-fan-out: insert the payment, decrement the customer balance,
  /// and distribute the payment across the given orders (oldest-first FIFO),
  /// all inside one transaction. Returns the new payment id.
  Future<int> recordPaymentDistributedAtomic(
    Payment payment,
    List<Order> ordersToSettle,
  ) async {
    final db = await DatabaseService.instance.database;
    int paymentId = 0;

    await db.transaction((txn) async {
      paymentId = await txn.insert('payments', payment.toMap());

      await txn.rawUpdate(
        'UPDATE customers SET previousBalance = previousBalance - ? WHERE id = ?',
        [payment.amount, payment.customerId],
      );

      // Oldest-first FIFO distribution across orders.
      final ordered = [...ordersToSettle]
        ..sort((a, b) => a.date.compareTo(b.date));

      double remaining = payment.amount;
      for (final order in ordered) {
        if (remaining <= 0) break;
        final outstanding = order.totalAmount - order.paidAmount;
        if (outstanding <= 0) continue;
        final applied =
            remaining >= outstanding ? outstanding : remaining;
        final newPaid = order.paidAmount + applied;
        final newStatus = newPaid >= order.totalAmount
            ? OrderStatus.completed.index
            : OrderStatus.pending.index;
        await txn.rawUpdate(
          'UPDATE orders SET paidAmount = ?, status = ? WHERE id = ?',
          [newPaid, newStatus, order.id],
        );
        remaining -= applied;
      }
    });

    return paymentId;
  }

  Future<void> updateCustomerBalance(int customerId, double amount) async {
    final db = await DatabaseService.instance.database;
    await db.rawUpdate(
      'UPDATE customers SET previousBalance = previousBalance - ? WHERE id = ?',
      [amount, customerId],
    );
  }

  Future<void> updateOrderPaidAmount(int orderId, double paidAmount) async {
    final db = await DatabaseService.instance.database;
    final newStatus = paidAmount >= (await _getOrderTotal(orderId))
        ? OrderStatus.completed.index
        : null;

    if (newStatus != null) {
      await db.rawUpdate(
        'UPDATE orders SET paidAmount = ?, status = ? WHERE id = ?',
        [paidAmount, newStatus, orderId],
      );
    } else {
      await db.rawUpdate(
        'UPDATE orders SET paidAmount = ? WHERE id = ?',
        [paidAmount, orderId],
      );
    }
  }

  Future<double> _getOrderTotal(int orderId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT totalAmount FROM orders WHERE id = ?',
      [orderId],
    );
    if (result.isEmpty) return 0;
    return (result.first['totalAmount'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getCustomerOutstanding(int customerId) async {
    final db = await DatabaseService.instance.database;

    // Get customer's previous balance
    final customerResult = await db.rawQuery(
      'SELECT previousBalance FROM customers WHERE id = ?',
      [customerId],
    );
    final previousBalance = customerResult.isNotEmpty
        ? (customerResult.first['previousBalance'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    // Get total unpaid from orders
    final ordersResult = await db.rawQuery(
      'SELECT COALESCE(SUM(totalAmount - paidAmount), 0) as outstanding FROM orders WHERE customerId = ? AND status != ?',
      [customerId, OrderStatus.cancelled.index],
    );
    final ordersOutstanding =
        (ordersResult.first['outstanding'] as num?)?.toDouble() ?? 0.0;

    return previousBalance + ordersOutstanding;
  }

  Future<List<Order>> getCustomerUnpaidOrders(int customerId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT * FROM orders WHERE customerId = ? AND status != ? AND totalAmount > paidAmount ORDER BY date ASC',
      [customerId, OrderStatus.cancelled.index],
    );
    return results.map((map) => Order.fromMap(map)).toList();
  }

  Future<List<LedgerEntry>> getCustomerLedger(int customerId) async {
    final db = await DatabaseService.instance.database;

    // Get customer's opening balance
    final customerResult = await db.rawQuery(
      'SELECT previousBalance FROM customers WHERE id = ?',
      [customerId],
    );
    final openingBalance = customerResult.isNotEmpty
        ? (customerResult.first['previousBalance'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    // Get all orders
    final ordersResult = await db.rawQuery(
      'SELECT * FROM orders WHERE customerId = ? AND status != ? ORDER BY date ASC',
      [customerId, OrderStatus.cancelled.index],
    );

    // Get all payments
    final paymentsResult = await db.rawQuery(
      'SELECT * FROM payments WHERE customerId = ? ORDER BY date ASC',
      [customerId],
    );

    // Build entries
    final entries = <LedgerEntry>[];

    // Add opening balance as first entry if exists
    if (openingBalance != 0) {
      entries.add(LedgerEntry(
        date: DateTime.now().subtract(const Duration(days: 365 * 10)),
        type: 'opening',
        description: 'Opening Balance',
        reference: 'OPENING',
        debit: openingBalance > 0 ? openingBalance : 0,
        credit: openingBalance < 0 ? -openingBalance : 0,
        runningBalance: openingBalance,
      ));
    }

    // Add orders
    for (final orderMap in ordersResult) {
      final order = Order.fromMap(orderMap);
      entries.add(LedgerEntry(
        date: order.date,
        type: 'order',
        description: 'Invoice: ${order.invoiceNumber}',
        reference: order.invoiceNumber,
        debit: order.totalAmount,
        credit: 0,
        runningBalance: 0,
      ));
    }

    // Add payments
    for (final paymentMap in paymentsResult) {
      final payment = Payment.fromMap(paymentMap);
      entries.add(LedgerEntry(
        date: payment.date,
        type: 'payment',
        description: payment.type == PaymentType.incoming
            ? 'Payment Received'
            : 'Refund Issued',
        reference: 'PAY-${payment.id}',
        debit: payment.type == PaymentType.outgoing ? payment.amount : 0,
        credit: payment.type == PaymentType.incoming ? payment.amount : 0,
        runningBalance: 0,
        semanticType: payment.semanticType,
        notes: payment.notes,
      ));
    }

    // Sort by date
    entries.sort((a, b) => a.date.compareTo(b.date));

    // Calculate running balance
    double runningBalance = 0;
    final entriesWithBalance = <LedgerEntry>[];
    for (final entry in entries) {
      runningBalance += entry.debit - entry.credit;
      entriesWithBalance.add(LedgerEntry(
        date: entry.date,
        type: entry.type,
        description: entry.description,
        reference: entry.reference,
        debit: entry.debit,
        credit: entry.credit,
        runningBalance: runningBalance,
        semanticType: entry.semanticType,
        notes: entry.notes,
      ));
    }

    return entriesWithBalance;
  }

  Future<List<Payment>> getCustomerPayments(int customerId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'payments',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return results.map((map) => Payment.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int customerId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );
    if (results.isEmpty) return null;
    return Customer.fromMap(results.first);
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await DatabaseService.instance.database;
    final results = await db.query('customers', orderBy: 'shopName ASC');
    return results.map((map) => Customer.fromMap(map)).toList();
  }
}
