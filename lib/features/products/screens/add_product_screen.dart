// lib/features/products/screens/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/products/repositories/product_repository.dart';
import 'package:toko_app/features/products/providers/add_product_notifier.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productRepository = ProductRepository();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taxController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addProductNotifierProvider.notifier).loadInitialData();
      if (widget.existingProduct != null) {
        _populateForm(widget.existingProduct!);
      }
    });
  }

  void _populateForm(Product product) {
    _nameController.text = product.name;
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _buyingPriceController.text = product.buyingPrice.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _wholesalePriceController.text = product.wholesalePrice.toString();
    _stockController.text = product.stock.toString();
    _minStockController.text = product.minStock.toString();
    _descriptionController.text = '';
    _taxController.text = product.tax.toString();
    _discountController.text = product.discount.toString();

    final notifier = ref.read(addProductNotifierProvider.notifier);
    notifier.setSelectedCategory(product.category);
    notifier.setSelectedBrand(product.brand);
    notifier.setSelectedUnit(product.unit);
    notifier.setSelectedSupplierId(product.supplierId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _wholesalePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final notifier = ref.read(addProductNotifierProvider.notifier);
    await notifier.pickImage();
  }

  Future<void> _scanBarcode() async {
    final barcode = await context.push<String>('/barcode-scanner');
    if (barcode != null && barcode.isNotEmpty && barcode != '-1') {
      _barcodeController.text = barcode;
    }
  }

  void _generateSku() {
    final notifier = ref.read(addProductNotifierProvider.notifier);
    notifier.startGeneratingSku();

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final random = (DateTime.now().second * 17).toString().padLeft(4, '0');
    final sku = 'PRD-$timestamp$random';

    _skuController.text = sku;

    notifier.stopGeneratingSku();
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.pop(controller.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(addProductNotifierProvider.notifier).addCategory(result);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(addProductNotifierProvider.notifier);
    notifier.setSaving(true);

    try {
      final state = ref.read(addProductNotifierProvider);
      final product = Product(
        id: widget.existingProduct?.id,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        category: state.selectedCategory,
        brand: state.selectedBrand,
        buyingPrice: double.parse(_buyingPriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        wholesalePrice: double.parse(_wholesalePriceController.text),
        stock: int.parse(_stockController.text),
        minStock: int.parse(_minStockController.text),
        unit: state.selectedUnit!,
        supplierId: state.selectedSupplierId,
        tax: double.tryParse(_taxController.text) ?? 0.0,
        discount: double.tryParse(_discountController.text) ?? 0.0,
        imagePath: state.savedImagePath, // Include the compressed image path
      );

      if (widget.existingProduct != null) {
        await _productRepository.updateProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        }
      } else {
        await _productRepository.addProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      notifier.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProduct != null ? 'Edit Product' : 'Add Product'),
        actions: [
          if (state.isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProduct,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(state),
            const SizedBox(height: 24),
            _buildBasicInfoSection(state),
            const SizedBox(height: 24),
            _buildPricingSection(),
            const SizedBox(height: 24),
            _buildInventorySection(state), // FIXED: Added state parameter
            const SizedBox(height: 24),
            _buildAdditionalInfoSection(state),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.isSaving ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.existingProduct != null ? 'Update Product' : 'Save Product',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(AddProductState state) {
    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100, // Reduced size for smaller display
          height: 100, // Reduced size for smaller display
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).round()),
              width: 2,
            ),
          ),
          child: state.savedImagePath != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(state.savedImagePath!),
              fit: BoxFit.cover,
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo,
                size: 36, // Smaller icon
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 6),
              Text(
                'Add Image',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Smaller text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(AddProductState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: state.isGeneratingSku ? null : _generateSku,
                  icon: state.isGeneratingSku
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.autorenew),
                  tooltip: 'Generate SKU',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: state.selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: [
                      ...state.categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      )),
                    ],
                    onChanged: (value) {
                      ref.read(addProductNotifierProvider.notifier).setSelectedCategory(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add New Category',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.selectedBrand,
              decoration: const InputDecoration(
                labelText: 'Brand',
                prefixIcon: Icon(Icons.branding_watermark),
              ),
              onChanged: (value) {
                ref.read(addProductNotifierProvider.notifier).setSelectedBrand(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Buying Price *',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Buying price is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid price';
                }
                if (double.parse(value) < 0) {
                  return 'Price cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price *',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selling price is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid price';
                }
                if (double.parse(value) < 0) {
                  return 'Price cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wholesalePriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Wholesale Price *',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Wholesale price is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid price';
                }
                if (double.parse(value) < 0) {
                  return 'Price cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tax %',
                      prefixIcon: Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid tax percentage';
                        }
                        final tax = double.parse(value);
                        if (tax < 0 || tax > 100) {
                          return 'Tax must be between 0-100%';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount %',
                      prefixIcon: Icon(Icons.local_offer),
                      suffixText: '%',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Invalid discount percentage';
                        }
                        final discount = double.parse(value);
                        if (discount < 0 || discount > 100) {
                          return 'Discount must be between 0-100%';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(AddProductState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: state.selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Unit *',
                prefixIcon: Icon(Icons.straighten),
              ),
              items: state.units.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (value) {
                ref.read(addProductNotifierProvider.notifier).setSelectedUnit(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Unit is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity *',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Stock quantity is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid quantity';
                      }
                      if (int.parse(value) < 0) {
                        return 'Stock cannot be negative';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Stock Alert *',
                      prefixIcon: Icon(Icons.warning),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Minimum stock is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid quantity';
                      }
                      if (int.parse(value) < 0) {
                        return 'Stock cannot be negative';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(AddProductState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: state.selectedSupplierId,
              decoration: const InputDecoration(
                labelText: 'Supplier',
                prefixIcon: Icon(Icons.supervisor_account),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Supplier')),
                ...state.suppliers.map((supplier) {
                  return DropdownMenuItem(
                    value: supplier['id'] as int,
                    child: Text(supplier['name'] as String),
                  );
                }),
              ],
              onChanged: (value) {
                ref.read(addProductNotifierProvider.notifier).setSelectedSupplierId(value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Barcode Scanner Screen using mobile_scanner
class _BarcodeScannerScreen extends ConsumerStatefulWidget {
  const _BarcodeScannerScreen();

  @override
  ConsumerState<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<_BarcodeScannerScreen> {
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
            onPressed: () => context.pop(),
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
              context.pop(barcode);
            }
          }
        },
      ),
    );
  }
}