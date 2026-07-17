// lib/features/brands/repositories/brand_repository.dart
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/brands/models/brand_model.dart';

class BrandRepository {
  Future<List<Brand>> getAllBrands() async {
    final db = await DatabaseService.instance.database;
    final results = await db.query('brands', orderBy: 'name ASC');
    return results.map((map) => Brand.fromMap(map)).toList();
  }

  Future<Brand?> getBrandById(int id) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'brands',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Brand.fromMap(results.first);
  }

  Future<Brand?> getBrandByName(String name) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'brands',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (results.isEmpty) return null;
    return Brand.fromMap(results.first);
  }

  Future<int> addBrand(Brand brand) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('brands', brand.toMap());
  }

  Future<int> updateBrand(Brand brand) async {
    final db = await DatabaseService.instance.database;
    return await db.update(
      'brands',
      brand.toMap(),
      where: 'id = ?',
      whereArgs: [brand.id],
    );
  }

  Future<int> deleteBrand(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete(
      'brands',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getProductCountByBrand(String brandName) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE brand = ?',
      [brandName],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
