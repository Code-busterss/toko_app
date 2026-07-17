// lib/features/stock/repositories/stock_adjustment_repository.dart

import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/stock/models/stock_adjustment_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class StockAdjustmentRepository {
  // Get all adjustments
  Future<List<StockAdjustment>> getAllAdjustments() async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'stock_adjustments',
      orderBy: 'date DESC',
    );
    return results.map((m) => StockAdjustment.fromMap(m)).toList();
  }

  // Get adjustments for specific product
  Future<List<StockAdjustment>> getAdjustmentsByProductId(int productId) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'stock_adjustments',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
    return results.map((m) => StockAdjustment.fromMap(m)).toList();
  }

  // Add new adjustment and update product stock
  Future<void> addAdjustment(StockAdjustment adjustment) async {
    final db = await DatabaseService.instance.database;

    await db.transaction((txn) async {
      // Insert adjustment
      await txn.insert('stock_adjustments', adjustment.toMap());

      // Update product stock
      final productResult = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [adjustment.productId],
      );

      if (productResult.isNotEmpty) {
        final currentStock = productResult.first['stock'] as int;
        int newStock = currentStock;

        // Calculate new stock based on adjustment type
        switch (adjustment.type) {
        case AdjustmentType.add:
        case AdjustmentType.returned:
        newStock = currentStock + adjustment.quantity;
        break;
        case AdjustmentType.subtract:
        case AdjustmentType.damage:
        case AdjustmentType.expired:
        newStock = currentStock - adjustment.quantity;
        break;
        }

        // Ensure stock doesn't go negative
        if (newStock < 0) newStock = 0;

        await txn.update(
          'products',
          {'stock': newStock},
          where: 'id = ?',
          whereArgs: [adjustment.productId],
        );
      }
    });
  }

  // Delete adjustment (and reverse stock change)
  Future<void> deleteAdjustment(int id) async {
    final db = await DatabaseService.instance.database;

    await db.transaction((txn) async {
      // Get adjustment details
      final adjustmentResult = await txn.query(
        'stock_adjustments',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (adjustmentResult.isNotEmpty) {
        final adjustment = StockAdjustment.fromMap(adjustmentResult.first);

        // Reverse the stock change
        final productResult = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [adjustment.productId],
        );

        if (productResult.isNotEmpty) {
          final currentStock = productResult.first['stock'] as int;
          int newStock = currentStock;

          // Reverse the adjustment
          switch (adjustment.type) {
          case AdjustmentType.add:
          case AdjustmentType.returned:
          newStock = currentStock - adjustment.quantity;
          break;
          case AdjustmentType.subtract:
          case AdjustmentType.damage:
          case AdjustmentType.expired:
          newStock = currentStock + adjustment.quantity;
          break;
          }

          if (newStock < 0) newStock = 0;

          await txn.update(
            'products',
            {'stock': newStock},
            where: 'id = ?',
            whereArgs: [adjustment.productId],
          );
        }

        // Delete adjustment
        await txn.delete(
          'stock_adjustments',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }
}