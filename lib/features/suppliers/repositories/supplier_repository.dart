// lib/features/suppliers/repositories/supplier_repository.dart
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/purchases/models/purchase_model.dart';
import 'package:toko_app/features/suppliers/models/supplier_model.dart';

class SupplierRepository {
  Future<List<Supplier>> getAllSuppliers() async {
    final db = await DatabaseService.instance.database;
    final results = await db.query('suppliers', orderBy: 'name ASC');
    return results.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<Supplier?> getSupplierById(int id) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Supplier.fromMap(results.first);
  }

  Future<int> addSupplier(Supplier supplier) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await DatabaseService.instance.database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  /// Increase the running totals on a supplier after a purchase.
  /// Runs in a transaction so totals stay consistent with purchases.
  Future<void> addToSupplierTotals({
    required int supplierId,
    required double amount,
  }) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE suppliers SET totalPurchases = totalPurchases + ?, '
        'pendingAmount = pendingAmount + ? WHERE id = ?',
        [amount, amount, supplierId],
      );
    });
  }

  /// Reduce the pending amount on a supplier after a payment to them.
  Future<void> reducePending(int supplierId, double amount) async {
    final db = await DatabaseService.instance.database;
    await db.rawUpdate(
      'UPDATE suppliers SET pendingAmount = MAX(0, pendingAmount - ?) WHERE id = ?',
      [amount, supplierId],
    );
  }

  Future<List<Purchase>> getSupplierPurchases(int supplierId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'purchases',
      where: 'supplierId = ?',
      whereArgs: [supplierId],
      orderBy: 'purchaseDate DESC',
    );
    return results.map((map) => Purchase.fromMap(map)).toList();
  }

  /// Total amount paid to a supplier (sum of payments to suppliers if a
  /// supplier-payments table existed). For now we derive pending from the
  /// supplier row's pendingAmount column.
  Future<double> getPendingAmount(int supplierId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT pendingAmount FROM suppliers WHERE id = ?',
      [supplierId],
    );
    if (results.isEmpty) return 0;
    return (results.first['pendingAmount'] as num?)?.toDouble() ?? 0.0;
  }
}
