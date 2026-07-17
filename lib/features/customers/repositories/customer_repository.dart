// lib/features/customers/repositories/customer_repository.dart
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/payments/models/payment_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class CustomerStats {
  final int totalOrders;
  final double totalPaid;
  final double remainingBalance;
  final int pendingOrders;

  CustomerStats({
    required this.totalOrders,
    required this.totalPaid,
    required this.remainingBalance,
    required this.pendingOrders,
  });
}

class CustomerRepository {
  Future<List<Customer>> getAllCustomers() async {
    final db = await DatabaseService.instance.database;
    final results = await db.query('customers', orderBy: 'shopName ASC');
    return results.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Customer.fromMap(results.first);
  }

  Future<Customer?> getCustomerByPhone(String phone) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'customers',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (results.isEmpty) return null;
    return Customer.fromMap(results.first);
  }

  Future<int> addCustomer(Customer customer) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await DatabaseService.instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<CustomerStats> getCustomerStats(int customerId) async {
    final db = await DatabaseService.instance.database;

    // Total orders
    final ordersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE customerId = ? AND status != ?',
      [customerId, OrderStatus.cancelled.index],
    );
    final totalOrders = (ordersResult.first['count'] as int?) ?? 0;

    // Pending orders
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE customerId = ? AND status = ?',
      [customerId, OrderStatus.pending.index],
    );
    final pendingOrders = (pendingResult.first['count'] as int?) ?? 0;

    // Total paid (from orders)
    final paidResult = await db.rawQuery(
      'SELECT SUM(paidAmount) as total FROM orders WHERE customerId = ? AND status != ?',
      [customerId, OrderStatus.cancelled.index],
    );
    final paidFromOrders = (paidResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Total from payments table
    final paymentsResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE customerId = ? AND type = ?',
      [customerId, PaymentType.incoming.index],
    );
    final paidFromPayments = (paymentsResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Total order amount
    final totalAmountResult = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM orders WHERE customerId = ? AND status != ?',
      [customerId, OrderStatus.cancelled.index],
    );
    final totalOrderAmount = (totalAmountResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Get customer for previous balance
    final customer = await getCustomerById(customerId);
    final previousBalance = customer?.previousBalance ?? 0.0;

    final totalPaid = paidFromOrders + paidFromPayments;
    final remainingBalance = (totalOrderAmount + previousBalance) - totalPaid;

    return CustomerStats(
      totalOrders: totalOrders,
      totalPaid: totalPaid,
      remainingBalance: remainingBalance,
      pendingOrders: pendingOrders,
    );
  }

  Future<List<Order>> getCustomerOrders(int customerId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'orders',
      where: 'customerId = ? AND status != ?',
      whereArgs: [customerId, OrderStatus.cancelled.index],
      orderBy: 'date DESC',
    );
    return results.map((map) => Order.fromMap(map)).toList();
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

  Future<List<Order>> getCustomerPendingBills(int customerId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT * FROM orders WHERE customerId = ? AND status != ? AND totalAmount > paidAmount ORDER BY date ASC',
      [customerId, OrderStatus.cancelled.index],
    );
    return results.map((map) => Order.fromMap(map)).toList();
  }
}
