// lib/features/products/screens/import_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/services/excel_service.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/products/providers/product_notifier.dart';

import '../../../core/constants/constants.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  final ImportResult importResult;

  const ImportPreviewScreen({
    super.key,
    required this.importResult,
  });

  @override
  ConsumerState<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  bool _isSaving = false;
  List<Product> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _selectedProducts = List.from(widget.importResult.products);
  }

  Future<void> _saveProducts() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    final notifier = ref.read(productNotifierProvider.notifier);

    for (final product in _selectedProducts) {
      try {
        await notifier.addProduct(product);
        successCount++;
      } catch (e) {
        errorCount++;
        errors.add('${product.name}: $e');
      }
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Import Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('Imported: $successCount products'),
              ],
            ),
            if (errorCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Failed: $errorCount products'),
                ],
              ),
            ],
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors
                        .take(10)
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• $e', style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.pop(true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll(bool? value) {
    if (value == true) {
      _selectedProducts = List.from(widget.importResult.products);
    } else {
      _selectedProducts = [];
    }
    setState(() {});
  }

  void _toggleProduct(Product product, bool? selected) {
    if (selected == true) {
      _selectedProducts.add(product);
    } else {
      _selectedProducts.removeWhere((p) => p.name == product.name && p.sku == product.sku);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.importResult;
    final allSelected = _selectedProducts.length == result.products.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Preview'),
        actions: [
          if (_selectedProducts.isNotEmpty && !_isSaving)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProducts,
              tooltip: 'Save Selected',
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Total Rows', '${result.totalRows}'),
                _buildSummaryRow(
                  'Valid Products',
                  '${result.successCount}',
                  color: Colors.green,
                ),
                if (result.hasErrors)
                  _buildSummaryRow(
                    'Errors',
                    '${result.errors.length}',
                    color: Colors.red,
                  ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Selected: ${_selectedProducts.length} of ${result.products.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // Checkbox header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: _toggleSelectAll,
                ),
                const Expanded(
                  child: Text(
                    'Select All',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: ListView.builder(
              itemCount: result.products.length,
              itemBuilder: (context, index) {
                final product = result.products[index];
                final isSelected = _selectedProducts.any(
                  (p) => p.name == product.name && p.sku == product.sku,
                );

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) => _toggleProduct(product, value),
                  title: Text(product.name),
                  subtitle: Text(
                    [
                      if (product.sku.isNotEmpty) 'SKU: ${product.sku}',
                      if (product.barcode.isNotEmpty) 'Barcode: ${product.barcode}',
                    ].join(' • '),
                  ),
                  secondary: Text(
                    '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                );
              },
            ),
          ),

          // Bottom bar
          if (_isSaving)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Saving products...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}
                      ),
                ),
              ],
            ),
          ),

          // Errors section
          if (result.hasErrors)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Import Errors',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: result.errors
                            .map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('• $e', style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Select all checkbox
          if (result.products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    onChanged: _toggleSelectAll,
                  ),
                  const SizedBox(width: 8),
                  const Text('Select All', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${_selectedProducts.length} selected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Products list
          Expanded(
            child: result.products.isEmpty
                ? const Center(
                    child: Text('No valid products to import'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: result.products.length,
                    itemBuilder: (context, index) {
                      final product = result.products[index];
                      final isSelected = _selectedProducts.any(
                        (p) => p.name == product.name && p.sku == product.sku,
                      );
                      return _buildProductPreview(context, product, isSelected);
                    },
                  ),
          ),

          // Save button
          if (result.products.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProducts,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Import ${_selectedProducts.length} Products',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPreview(BuildContext context, Product product, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => _toggleProduct(product, value),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (product.sku != null && product.sku!.isNotEmpty)
                  Text(
                    'SKU: ${product.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (product.sku != null && product.sku!.isNotEmpty)
                  const SizedBox(width: 12),
                Text(
                  '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(product.category ?? 'No Category', Colors.blue),
                const SizedBox(width: 4),
                _buildChip('Stock: ${product.stock}', Colors.green),
                const SizedBox(width: 4),
                _buildChip(product.unit, Colors.purple),
              ],
            ),
          ],
        ),
        secondary: const Icon(Icons.inventory_2, size: 32),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
