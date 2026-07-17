import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/products/repositories/product_repository.dart';
import 'package:toko_app/features/stock/models/stock_adjustment_model.dart';
import 'package:toko_app/features/stock/repositories/stock_adjustment_repository.dart';

// ==========================================
// 1. STATE CLASSES
// ==========================================

class StockState {
  final List<Product> products;
  final List<StockAdjustment> adjustments;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final StockFilter filter;

  StockState({
    this.products = const [],
    this.adjustments = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filter = StockFilter.all,
  });

  StockState copyWith({
    List<Product>? products,
    List<StockAdjustment>? adjustments,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    StockFilter? filter,
  }) {
    return StockState(
      products: products ?? this.products,
      adjustments: adjustments ?? this.adjustments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }
}

enum StockFilter { all, inStock, lowStock, outOfStock }

// ==========================================
// 2. NOTIFIERS (Riverpod 2.x StateNotifier)
// ==========================================

// Main Stock List Notifier
class StockNotifier extends StateNotifier<StockState> {
  final ProductRepository _productRepository;
  final StockAdjustmentRepository _adjustmentRepository;

  StockNotifier(this._productRepository, this._adjustmentRepository)
      : super(StockState()) {
    loadStock();
  }

  Future<void> loadStock() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await _productRepository.getAllProducts();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(StockFilter filter) {
    state = state.copyWith(filter: filter);
  }

  List<Product> get filteredProducts {
    var filtered = state.products;

    // Apply search
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
            (p.sku?.toLowerCase().contains(state.searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply filter
    switch (state.filter) {
      case StockFilter.inStock:
        filtered = filtered.where((p) => p.stock > p.minStock).toList();
        break;
      case StockFilter.lowStock:
        filtered = filtered.where((p) => p.stock > 0 && p.stock <= p.minStock).toList();
        break;
      case StockFilter.outOfStock:
        filtered = filtered.where((p) => p.stock == 0).toList();
        break;
      case StockFilter.all:
        break;
    }

    return filtered;
  }

  int get totalProducts => state.products.length;
  int get inStockCount => state.products.where((p) => p.stock > p.minStock).length;
  int get lowStockCount => state.products.where((p) => p.stock > 0 && p.stock <= p.minStock).length;
  int get outOfStockCount => state.products.where((p) => p.stock == 0).length;
}

// Stock Adjustments Notifier (for history screen)
class StockAdjustmentsNotifier extends StateNotifier<StockState> {
  final StockAdjustmentRepository _repository;

  StockAdjustmentsNotifier(this._repository) : super(StockState()) {
    loadAdjustments();
  }

  Future<void> loadAdjustments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final adjustments = await _repository.getAllAdjustments();
      state = state.copyWith(adjustments: adjustments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadAdjustmentsByProductId(int productId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final adjustments = await _repository.getAdjustmentsByProductId(productId);
      state = state.copyWith(adjustments: adjustments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// ==========================================
// 3. PROVIDERS
// ==========================================

// ✅ NEW: Create ProductRepository instance directly here
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// Repository Provider for Stock Adjustments
final stockAdjustmentRepositoryProvider = Provider<StockAdjustmentRepository>((ref) {
  return StockAdjustmentRepository();
});

// Main Stock Provider
final stockNotifierProvider = StateNotifierProvider<StockNotifier, StockState>((ref) {
  return StockNotifier(
    ref.watch(productRepositoryProvider),
    ref.watch(stockAdjustmentRepositoryProvider),
  );
});

// History Adjustments Provider
final stockAdjustmentsNotifierProvider =
StateNotifierProvider<StockAdjustmentsNotifier, StockState>((ref) {
  return StockAdjustmentsNotifier(ref.watch(stockAdjustmentRepositoryProvider));
});