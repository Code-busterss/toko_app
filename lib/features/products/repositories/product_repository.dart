// lib/features/products/repositories/product_repository.dart
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/products/models/product_model.dart';

class ProductRepository {
  Future<List<Product>> getAllProducts() async {
    final db = await DatabaseService.instance.database;
    final results = await db.query('products', orderBy: 'name ASC');
    return results.map((map) => Product.fromMap(map)).toList();
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

  Future<Product?> getProductBySku(String sku) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
    );
    if (results.isEmpty) return null;
    return Product.fromMap(results.first);
  }

  Future<int> addProduct(Product product) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await DatabaseService.instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getCategories() async {
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != "" ORDER BY category',
    );
    return results.map((map) => map['category'] as String).toList();
  }

  Future<List<String>> getBrands() async {
    final db = await DatabaseService.instance.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT brand FROM products WHERE brand IS NOT NULL AND brand != "" ORDER BY brand',
    );
    return results.map((map) => map['brand'] as String).toList();
  }

  Future<List<String>> getUnits() async {
    return ['Pcs', 'Box', 'Kg', 'Gram', 'Liter', 'Meter', 'Pack', 'Dozen'];
  }

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await DatabaseService.instance.database;
    return await db.query('suppliers', orderBy: 'name ASC');
  }

  Future<void> updateStock(int productId, int newStock) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
