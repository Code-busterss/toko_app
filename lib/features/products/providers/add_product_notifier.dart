// lib/features/products/providers/add_product_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:toko_app/core/database_service.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/products/repositories/product_repository.dart';

class AddProductState {
  final bool isLoading;
  final bool isGeneratingSku;
  final bool isSaving;
  final String? errorMessage;
  final String? selectedCategory;
  final String? selectedBrand;
  final String? selectedUnit;
  final int? selectedSupplierId;
  final File? productImage;
  final List<String> categories;
  final List<String> units;
  final List<Map<String, dynamic>> suppliers;

  AddProductState({
    this.isLoading = false,
    this.isGeneratingSku = false,
    this.isSaving = false,
    this.errorMessage,
    this.selectedCategory,
    this.selectedBrand,
    this.selectedUnit,
    this.selectedSupplierId,
    this.productImage,
    this.categories = const [],
    this.units = const [],
    this.suppliers = const [],
  });

  AddProductState copyWith({
    bool? isLoading,
    bool? isGeneratingSku,
    bool? isSaving,
    String? errorMessage,
    String? selectedCategory,
    String? selectedBrand,
    String? selectedUnit,
    int? selectedSupplierId,
    File? productImage,
    List<String>? categories,
    List<String>? units,
    List<Map<String, dynamic>>? suppliers,
  }) {
    return AddProductState(
      isLoading: isLoading ?? this.isLoading,
      isGeneratingSku: isGeneratingSku ?? this.isGeneratingSku,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      selectedSupplierId: selectedSupplierId ?? this.selectedSupplierId,
      productImage: productImage ?? this.productImage,
      categories: categories ?? this.categories,
      units: units ?? this.units,
      suppliers: suppliers ?? this.suppliers,
    );
  }
}

class AddProductNotifier extends StateNotifier<AddProductState> {
  final ProductRepository _productRepository;
  final ImagePicker _imagePicker;

  AddProductNotifier(this._productRepository, this._imagePicker)
      : super(AddProductState());

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final categories = await _productRepository.getCategories();
      final units = await _productRepository.getUnits();
      final suppliers = await _productRepository.getSuppliers();

      state = state.copyWith(
        categories: categories,
        units: units,
        suppliers: suppliers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error loading data: $e',
        isLoading: false,
      );
    }
  }

  void setSelectedCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSelectedBrand(String? brand) {
    state = state.copyWith(selectedBrand: brand);
  }

  void setSelectedUnit(String? unit) {
    state = state.copyWith(selectedUnit: unit);
  }

  void setSelectedSupplierId(int? supplierId) {
    state = state.copyWith(selectedSupplierId: supplierId);
  }

  Future<void> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        state = state.copyWith(productImage: File(image.path));
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error picking image: $e');
    }
  }

  void clearImage() {
    state = state.copyWith(productImage: null);
  }

  void startGeneratingSku() {
    state = state.copyWith(isGeneratingSku: true);
  }

  void stopGeneratingSku() {
    state = state.copyWith(isGeneratingSku: false);
  }

  Future<void> addCategory(String categoryName) async {
    try {
      // Add category to database if needed, or just update local state
      final updatedCategories = List<String>.from(state.categories)..add(categoryName);
      state = state.copyWith(
        categories: updatedCategories,
        selectedCategory: categoryName,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error adding category: $e');
    }
  }

  void setSaving(bool value) {
    state = state.copyWith(isSaving: value);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = AddProductState(
      categories: state.categories,
      units: state.units,
      suppliers: state.suppliers,
    );
  }
}

final addProductNotifierProvider = StateNotifierProvider<AddProductNotifier, AddProductState>(
  (ref) => AddProductNotifier(ProductRepository(), ImagePicker()),
);
