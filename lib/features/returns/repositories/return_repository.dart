// lib/features/returns/repositories/return_repository.dart
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/returns/models/return_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class ReturnRepository {
  Future<void> ensureTable() async {
    final db = await DatabaseService.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        invoiceNumber TEXT NOT NULL,
        customerId INTEGER NOT NULL,
        customerName TEXT NOT NULL,
        items TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        reason TEXT NOT NULL,
        status INTEGER DEFAULT 0,
        refundIssued INTEGER DEFAULT 0,
        stockRestored INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT
      )
    ''');
  }

  Future<int> createReturn(SalesReturn salesReturn) async {
    await ensureTable();
    final db = await DatabaseService.instance.database;
    return await db.insert('sales_returns', salesReturn.toMap());
  }

  Future<SalesReturn?> getReturnById(int id) async {
    await ensureTable();
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'sales_returns',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return SalesReturn.fromMap(results.first);
  }

  Future<List<SalesReturn>> getReturnsByOrderId(int orderId) async {
    await ensureTable();
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'sales_returns',
      where: 'orderId = ?',
      whereArgs: [orderId],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => SalesReturn.fromMap(map)).toList();
  }

  Future<List<SalesReturn>> getReturnsByCustomerId(int customerId) async {
    await ensureTable();
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'sales_returns',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => SalesReturn.fromMap(map)).toList();
  }

  Future<List<SalesReturn>> getAllReturns() async {
    await ensureTable();
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'sales_returns',
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => SalesReturn.fromMap(map)).toList();
  }

  Future<void> updateReturnStatus(int returnId, ReturnStatus status) async {
    await ensureTable();
    final db = await DatabaseService.instance.database;
    await db.update(
      'sales_returns',
      {
        'status': status.index,
        'completedAt': status == ReturnStatus.completed
            ? DateTime.now().toIso8601String()
            : null,
      },
      where: 'id = ?',
      whereArgs: [returnId],
    );
  }

  Future<void> processReturn(SalesReturn salesReturn) async {
    final db = await DatabaseService.instance.database;

    await db.transaction((txn) async {
      // 1. Restore stock for each returned product
      for (final item in salesReturn.items) {
        if (item.productId != null) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [item.returnQty, item.productId],
          );
        }
      }

      // 2. Update order paidAmount (reduce it)
      await txn.rawUpdate(
        'UPDATE orders SET paidAmount = MAX(0, paidAmount - ?) WHERE id = ?',
        [salesReturn.totalAmount, salesReturn.orderId],
      );

      // 3. Update customer balance (increase outstanding)
      await txn.rawUpdate(
        'UPDATE customers SET previousBalance = previousBalance + ? WHERE id = ?',
        [salesReturn.totalAmount, salesReturn.customerId],
      );

      // 4. Mark return as completed
      if (salesReturn.id != null) {
        await txn.update(
          'sales_returns',
          {
            'status': ReturnStatus.completed.index,
            'refundIssued': 1,
            'stockRestored': 1,
            'completedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [salesReturn.id],
        );
      }
    });
  }

  Future<Order?> getOrderById(int orderId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
    if (results.isEmpty) return null;
    return Order.fromMap(results.first);
  }

  Future<List<Order>> getCompletedOrders() async {
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT o.*, c.shopName as customerName FROM orders o LEFT JOIN customers c ON o.customerId = c.id WHERE o.status != ? ORDER BY o.date DESC LIMIT 200',
      [OrderStatus.cancelled.index],
    );
    return results.map((map) {
      final order = Order.fromMap(map);
      return order;
    }).toList();
  }

  Future<Map<String, dynamic>?> getOrderWithCustomer(int orderId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT o.*, c.shopName as customerName, c.phone as customerPhone FROM orders o LEFT JOIN customers c ON o.customerId = c.id WHERE o.id = ?',
      [orderId],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<double> getTotalReturnedAmount(int orderId) async {
    await ensureTable();
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT COALESCE(SUM(totalAmount), 0) as total FROM sales_returns WHERE orderId = ? AND status = ?',
      [orderId, ReturnStatus.completed.index],
    );
    return (results.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
