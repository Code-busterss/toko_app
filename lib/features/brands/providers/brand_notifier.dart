// lib/features/brands/providers/brand_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/brands/models/brand_model.dart';
import 'package:toko_app/features/brands/repositories/brand_repository.dart';

class BrandState {
  final bool isLoading;
  final List<Brand> brands;
  final String? errorMessage;
  final String searchQuery;

  BrandState({
    this.isLoading = false,
    this.brands = const [],
    this.errorMessage,
    this.searchQuery = '',
  });

  BrandState copyWith({
    bool? isLoading,
    List<Brand>? brands,
    String? errorMessage,
    String? searchQuery,
  }) {
    return BrandState(
      isLoading: isLoading ?? this.isLoading,
      brands: brands ?? this.brands,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Brand> get filteredBrands {
    if (searchQuery.isEmpty) {
      return brands;
    }
    return brands
        .where((b) => b.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }
}

class BrandNotifier extends StateNotifier<BrandState> {
  final BrandRepository _repository;

  BrandNotifier(this._repository) : super(BrandState());

  Future<void> loadBrands() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final brands = await _repository.getAllBrands();
      state = state.copyWith(brands: brands, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error loading brands: $e',
        isLoading: false,
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addBrand(Brand brand) async {
    try {
      await _repository.addBrand(brand);
      await loadBrands();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error adding brand: $e');
      rethrow;
    }
  }

  Future<void> updateBrand(Brand brand) async {
    try {
      await _repository.updateBrand(brand);
      await loadBrands();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error updating brand: $e');
      rethrow;
    }
  }

  Future<void> deleteBrand(int id) async {
    try {
      await _repository.deleteBrand(id);
      await loadBrands();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error deleting brand: $e');
      rethrow;
    }
  }

  Future<int> getProductCountByBrand(String brandName) async {
    return await _repository.getProductCountByBrand(brandName);
  }

  Future<Brand?> getBrandByName(String name) async {
    return await _repository.getBrandByName(name);
  }
}

final brandNotifierProvider =
    StateNotifierProvider<BrandNotifier, BrandState>((ref) {
  return BrandNotifier(BrandRepository());
});
