// lib/features/products/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/products/providers/product_notifier.dart';
import 'package:toko_app/features/products/screens/add_product_screen.dart';
import 'package:toko_app/features/products/screens/barcode_screen.dart';
import 'package:toko_app/features/products/screens/import_preview_screen.dart';
import 'package:toko_app/core/services/excel_service.dart';

import '../../../core/constants/constants.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  final _excelService = ExcelService();
  bool _isSearching = false;
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(productNotifierProvider.notifier).setFilter(
      ref.read(productNotifierProvider.notifier).filter.copyWith(
        searchQuery: query,
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BarcodeScannerScreen()),
    );
    if (barcode != null && barcode.isNotEmpty && barcode != '-1') {
      final product = await ref
          .read(productNotifierProvider.notifier)
          .getProductByBarcode(barcode);

      if (mounted) {
        if (product != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found: ${product.name}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarcodeScreen(product: product),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _importProducts() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reading Excel file...'),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await _excelService.importProducts();

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (result == null) {
        // User cancelled file picker
        return;
      }

      if (result.products.isEmpty && result.errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No products found in file'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Navigate to preview screen
      final refresh = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ImportPreviewScreen(importResult: result),
        ),
      );

      if (refresh == true) {
        ref.read(productNotifierProvider.notifier).fetchProducts();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportProducts() async {
    final productsState = ref.read(productNotifierProvider);

    final List<Product> productsToExport;
    if (productsState is AsyncData<List<Product>>) {
      productsToExport = productsState.value;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (productsToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Products'),
        content: Text('Export ${productsToExport.length} products to Excel file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isExporting = true);

    try {
      final filePath = await _excelService.exportProducts(productsToExport);

      if (!mounted) return;

      setState(() => _isExporting = false);

      // Show success with share option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${productsToExport.length} products'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'SHARE',
            textColor: Colors.white,
            onPressed: () async {
              try {
                await _excelService.shareFile(filePath);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Share error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterDialog() {
    final currentFilter = ref.read(productNotifierProvider.notifier).filter;
    String? selectedCategory = currentFilter.category;
    String? selectedBrand = currentFilter.brand;
    bool lowStockOnly = currentFilter.lowStockOnly;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Products'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<String>>(
                  future: ref.read(productNotifierProvider.notifier).getCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            hintText: 'All Categories',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Categories')),
                            ...snapshot.data!.map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                FutureBuilder<List<String>>(
                  future: ref.read(productNotifierProvider.notifier).getBrands(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Brand', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedBrand,
                          decoration: const InputDecoration(
                            hintText: 'All Brands',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Brands')),
                            ...snapshot.data!.map((brand) => DropdownMenuItem(
                              value: brand,
                              child: Text(brand),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedBrand = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Low Stock Only'),
                  subtitle: const Text('Show products below minimum stock'),
                  value: lowStockOnly,
                  onChanged: (value) {
                    setState(() {
                      lowStockOnly = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(productNotifierProvider.notifier).clearFilter();
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(productNotifierProvider.notifier).setFilter(
                  ProductFilter(
                    searchQuery: currentFilter.searchQuery,
                    category: selectedCategory,
                    brand: selectedBrand,
                    lowStockOnly: lowStockOnly,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(productNotifierProvider.notifier).deleteProduct(product.id!);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(productNotifierProvider.notifier).fetchProducts();
      }
    });
  }

  void _navigateToEditProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(existingProduct: product),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(productNotifierProvider.notifier).fetchProducts();
      }
    });
  }

  void _navigateToBarcodeScreen(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productNotifierProvider);
    final filter = ref.read(productNotifierProvider.notifier).filter;
    final hasActiveFilter = filter.category != null ||
        filter.brand != null ||
        filter.lowStockOnly;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        )
            : const Text('Products'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _onSearchChanged('');
                }
              });
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilter,
              label: const Text('!'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterDialog,
          ),
          PopupMenuButton<String>(
            icon: _isExporting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'scan':
                  _scanBarcode();
                  break;
                case 'import':
                  _importProducts();
                  break;
                case 'export':
                  _exportProducts();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20),
                    SizedBox(width: 8),
                    Text('Scan Barcode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, size: 20),
                    SizedBox(width: 8),
                    Text('Import from Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 20),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: productsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(productNotifierProvider.notifier).fetchProducts();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (products) => products.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round()),
              ),
              const SizedBox(height: 16),
              Text(
                hasActiveFilter ? 'No products match your filter' : 'No products yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                ),
              ),
              if (hasActiveFilter) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(productNotifierProvider.notifier).clearFilter();
                  },
                  child: const Text('Clear Filter'),
                ),
              ],
              const SizedBox(height: 16),
              if (!hasActiveFilter)
                OutlinedButton.icon(
                  onPressed: _importProducts,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import from Excel'),
                ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: () async {
            await ref.read(productNotifierProvider.notifier).fetchProducts();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(context, product);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final isLowStock = product.stock <= product.minStock;
    final stockColor = isLowStock ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _navigateToBarcodeScreen(product);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildProductImage(context, product),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product.sku ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: stockColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.stock} ${product.unit}',
                          style: TextStyle(
                            color: stockColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isLowStock) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LOW STOCK',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${AppConstants.currencySymbol} ${product.sellingPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _navigateToEditProduct(product);
                          break;
                        case 'barcode':
                          _navigateToBarcodeScreen(product);
                          break;
                        case 'delete':
                          _showDeleteDialog(product);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'barcode',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code, size: 20),
                            SizedBox(width: 8),
                            Text('View Barcode'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, Product product) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2,
        size: 40,
        color: Theme.of(context).colorScheme.primary.withAlpha((0.5 * 255).round()),
      ),
    );
  }
}

// Barcode Scanner Screen using mobile_scanner
class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.code128, BarcodeFormat.ean13],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first.rawValue;
            if (barcode != null) {
              Navigator.pop(context, barcode);
            }
          }
        },
      ),
    );
  }
}