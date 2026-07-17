// lib/features/stock/screens/stock_adjustment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:toko_app/core/theme/theme.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/stock/models/stock_adjustment_model.dart';
import 'package:toko_app/features/stock/providers/stock_notifier.dart';
import 'package:toko_app/features/stock/repositories/stock_adjustment_repository.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class StockAdjustmentFormState {
  final Product? selectedProduct;
  final AdjustmentType? selectedType;
  final DateTime selectedDate;
  final bool isSaving;
  final String? errorMessage;
  final bool saved;

  const StockAdjustmentFormState({
    this.selectedProduct,
    this.selectedType,
    required this.selectedDate,
    this.isSaving = false,
    this.errorMessage,
    this.saved = false,
  });

  StockAdjustmentFormState copyWith({
    Product? selectedProduct,
    AdjustmentType? selectedType,
    DateTime? selectedDate,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? saved,
  }) {
    return StockAdjustmentFormState(
      selectedProduct: selectedProduct ?? this.selectedProduct,
      selectedType: selectedType ?? this.selectedType,
      selectedDate: selectedDate ?? this.selectedDate,
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      saved: saved ?? this.saved,
    );
  }
}

class StockAdjustmentFormNotifier
    extends StateNotifier<StockAdjustmentFormState> {
  StockAdjustmentFormNotifier()
      : super(StockAdjustmentFormState(selectedDate: DateTime.now()));

  void selectProduct(Product p) =>
      state = state.copyWith(selectedProduct: p);
  void selectType(AdjustmentType t) =>
      state = state.copyWith(selectedType: t);
  void selectDate(DateTime d) => state = state.copyWith(selectedDate: d);
  void clearError() => state = state.copyWith(clearError: true);
  void setSaving(bool v) => state = state.copyWith(isSaving: v);
}

final stockAdjustmentFormProvider = StateNotifierProvider<
    StockAdjustmentFormNotifier, StockAdjustmentFormState>((ref) {
  return StockAdjustmentFormNotifier();
});

class StockAdjustmentScreen extends ConsumerStatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  ConsumerState<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState
    extends ConsumerState<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final form = ref.read(stockAdjustmentFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: form.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != form.selectedDate) {
      ref.read(stockAdjustmentFormProvider.notifier).selectDate(picked);
    }
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    final form = ref.read(stockAdjustmentFormProvider);
    final notifier = ref.read(stockAdjustmentFormProvider.notifier);

    if (form.selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }
    if (form.selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select adjustment type')),
      );
      return;
    }

    notifier.setSaving(true);
    try {
      final adjustment = StockAdjustment(
        productId: form.selectedProduct!.id!,
        type: form.selectedType!,
        quantity: int.parse(_quantityController.text),
        reason:
            _reasonController.text.isEmpty ? null : _reasonController.text,
        date: form.selectedDate.toIso8601String(),
      );

      final repository = ref.read(stockAdjustmentRepositoryProvider);
      await repository.addAdjustment(adjustment);
      await ref.read(stockNotifierProvider.notifier).loadStock();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock adjustment saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) notifier.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(stockNotifierProvider).products;
    final form = ref.watch(stockAdjustmentFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Adjustment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('1. Select Product'),
            const SizedBox(height: 8),
            DropdownButtonFormField<Product>(
              value: form.selectedProduct,
              decoration: AppTheme.inputDecoration(label: 'Product'),
              items: products.map((product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  child: Text(product.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(stockAdjustmentFormProvider.notifier)
                      .selectProduct(value);
                }
              },
              validator: (value) =>
                  value == null ? 'Please select a product' : null,
            ),
            if (form.selectedProduct != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Stock:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${form.selectedProduct!.stock} ${form.selectedProduct!.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle('2. Adjustment Type'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AdjustmentType.values.map((type) {
                final isSelected = form.selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(stockAdjustmentFormProvider.notifier)
                          .selectType(type);
                    }
                  },
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('3. Quantity'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: AppTheme.inputDecoration(
                label: 'Quantity',
                hint: 'Enter quantity',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (int.parse(value) <= 0) {
                  return 'Quantity must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('4. Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(form.selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('5. Reason (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: AppTheme.inputDecoration(
                label: 'Reason',
                hint: 'Enter reason for adjustment',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: form.isSaving ? null : _saveAdjustment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: form.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Adjustment',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
