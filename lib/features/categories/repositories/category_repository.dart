// lib/features/categories/repositories/category_repository.dart
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/categories/models/category_model.dart';

class CategoryRepository {
  Future<List<Category>> getAllCategories() async {
    final db = await DatabaseService.instance.database;
    final results = await db.query('categories', orderBy: 'name ASC');
    return results.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  Future<Category?> getCategoryByName(String name) async {
    final db = await DatabaseService.instance.database;
    final results = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  Future<int> addCategory(Category category) async {
    final db = await DatabaseService.instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await DatabaseService.instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await DatabaseService.instance.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getProductCountByCategory(String categoryName) async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category = ?',
      [categoryName],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
