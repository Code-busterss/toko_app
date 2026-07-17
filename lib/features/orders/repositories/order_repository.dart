// lib/features/orders/repositories/order_repository.dart
import 'dart:convert';
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/products/models/product_model.dart';

class OrderRepository {
  Future<String> generateInvoiceNumber() async {
    final db = await DatabaseService.instance.database;
    final today = DateTime.now();
    final prefix = 'INV-${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      "SELECT invoiceNumber FROM orders WHERE invoiceNumber LIKE ? ORDER BY invoiceNumber DESC LIMIT 1",
      ['$prefix%'],
    );

    int nextNumber = 1;
    if (result.isNotEmpty) {
      final lastInvoice = result.first['invoiceNumber'] as String;
      final parts = lastInvoice.split('-');
      if (parts.length >= 3) {
        final lastNum = int.tryParse(parts.last) ?? 0;
        nextNumber = lastNum + 1;
      }
    }

    return '$prefix-${nextNumber.toString().padLeft(4, '0')}';
  }

  Future<int> createOrder(Order order, {bool deductStock = true}) async {
    final db = await DatabaseService.instance.database;

    return await db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap());

      if (deductStock) {
        for (final item in order.items) {
          if (item.productId != null) {
            await txn.rawUpdate(
              'UPDATE products SET stock = stock - ? WHERE id = ?',
              [item.qty, item.productId],
            );
          }
        }
      }

      return orderId;
    });
  }

  Future<void> updateOrder(Order order) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> updateCustomerBalance(int customerId, double amountChange) async {
    final db = await DatabaseService.instance.database;
    await db.rawUpdate(
      'UPDATE customers SET previousBalance = previousBalance + ? WHERE id = ?',
      [amountChange, customerId],
    );
  }

  Future<Product?> getProductById(int id) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
      limit: 50,
    );
    return results.map((map) => Product.fromMap(map)).toList();
  }
}
