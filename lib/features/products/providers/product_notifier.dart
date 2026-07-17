// lib/features/products/providers/product_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/products/models/product_model.dart';

class ProductFilter {
  final String searchQuery;
  final String? category;
  final String? brand;
  final bool lowStockOnly;

  const ProductFilter({
    this.searchQuery = '',
    this.category,
    this.brand,
    this.lowStockOnly = false,
  });

  ProductFilter copyWith({
    String? searchQuery,
    String? category,
    String? brand,
    bool? lowStockOnly,
  }) {
    return ProductFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
    );
  }

  ProductFilter clear() {
    return const ProductFilter();
  }
}

class ProductNotifier extends Notifier<AsyncValue<List<Product>>> {
  ProductFilter _filter = const ProductFilter();

  ProductFilter get filter => _filter;

  @override
  AsyncValue<List<Product>> build() {
    fetchProducts();
    return const AsyncLoading();
  }

  void setFilter(ProductFilter newFilter) {
    _filter = newFilter;
    fetchProducts();
  }

  void clearFilter() {
    _filter = const ProductFilter();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = const AsyncLoading();
    try {
      final db = await DatabaseService.instance.database;
      
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (_filter.searchQuery.isNotEmpty) {
        whereClauses.add('(name LIKE ? OR sku LIKE ? OR barcode LIKE ?)');
        whereArgs.addAll([
          '%\${_filter.searchQuery}%',
          '%\${_filter.searchQuery}%',
          '%\${_filter.searchQuery}%',
        ]);
      }

      if (_filter.category != null && _filter.category!.isNotEmpty) {
        whereClauses.add('category = ?');
        whereArgs.add(_filter.category);
      }

      if (_filter.brand != null && _filter.brand!.isNotEmpty) {
        whereClauses.add('brand = ?');
        whereArgs.add(_filter.brand);
      }

      if (_filter.lowStockOnly) {
        whereClauses.add('stock <= minStock');
      }

      final whereClause = whereClauses.isNotEmpty 
          ? 'WHERE '
          : '';

      final results = await db.query(
        'products',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'name ASC',
      );

      final products = results.map((map) => Product.fromMap(map)).toList();
      state = AsyncData(products);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
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

  Future<int> addProduct(Product product) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert('products', product.toMap());
    await fetchProducts();
    return id;
  }

  Future<void> updateProduct(Product product) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await fetchProducts();
  }

  Future<void> deleteProduct(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchProducts();
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
}

final productNotifierProvider = NotifierProvider<ProductNotifier, AsyncValue<List<Product>>>(
  ProductNotifier.new,
);
