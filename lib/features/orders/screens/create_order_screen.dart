// lib/features/orders/screens/create_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/customers/repositories/customer_repository.dart';
import 'package:toko_app/features/orders/providers/order_notifier.dart';
import 'package:toko_app/features/orders/repositories/order_repository.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

import '../../../core/database_service.dart';
import '../models/order_model.dart';
import 'invoice_preview_screen.dart';

// Provider for current step state
final currentStepProvider = StateProvider<int>((ref) => 0);

class CreateOrderScreen extends ConsumerWidget {
  const CreateOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reset order draft when screen initializes
    ref.listen(orderNotifierProvider, (_, __) {}); // Listen to trigger rebuilds
    ref.listen(currentStepProvider, (_, __) {}); // Listen to trigger rebuilds

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Order?'),
                  content: const Text(
                      'Are you sure you want to cancel? All data will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Yes, Cancel'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildStepIndicator(ref, context),
        ),
      ),
      body: _buildBody(ref, context),
    );
  }

  Widget _buildStepIndicator(WidgetRef ref, BuildContext context) {
    final currentStep = ref.watch(currentStepProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepDot(currentStep, 0, 'Customer', context),
          _buildStepLine(currentStep),
          _buildStepDot(currentStep, 1, 'Products', context),
          _buildStepLine(currentStep),
          _buildStepDot(currentStep, 2, 'Summary', context),
        ],
      ),
    );
  }

  Widget _buildStepDot(int currentStep, int step, String label, BuildContext context) {
    final isActive = currentStep == step;
    final isCompleted = currentStep > step;
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : isCompleted
        ? Colors.green
        : Colors.grey;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                '${step + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int currentStep) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: currentStep > 0 ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildBody(WidgetRef ref, BuildContext context) {
    final currentStep = ref.watch(currentStepProvider);

    return IndexedStack(
      index: currentStep,
      children: [
        _Step1CustomerSelection(
          onNext: () => ref.read(currentStepProvider.notifier).state++,
        ),
        _Step2AddProducts(
          onNext: () => ref.read(currentStepProvider.notifier).state++,
          onBack: () => ref.read(currentStepProvider.notifier).state--,
        ),
        _Step3OrderSummary(
          onBack: () => ref.read(currentStepProvider.notifier).state--,
          onSave: () async {
            try {
              final invoiceNumber = await ref
                  .read(orderNotifierProvider.notifier)
                  .saveOrder();

              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        SizedBox(width: 8),
                        Text('Order Created'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order has been saved successfully!'),
                        const SizedBox(height: 12),
                        Text(
                          'Invoice: $invoiceNumber',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context, true);
                        },
                        child: const Text('Close'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final db = await DatabaseService.instance.database;
                          final results = await db.query(
                            'orders',
                            where: 'invoiceNumber = ?',
                            whereArgs: [invoiceNumber],
                            limit: 1,
                          );
                          if (results.isNotEmpty && context.mounted) {
                            final order = Order.fromMap(results.first);
                            Navigator.pop(context, true); // Pop to previous screen
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoicePreviewScreen(order: order),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.receipt),
                        label: const Text('View Invoice'),
                      ),
                    ],
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

// STEP 1: Customer Selection
class _Step1CustomerSelection extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _Step1CustomerSelection({required this.onNext});

  @override
  ConsumerState<_Step1CustomerSelection> createState() =>
      _Step1CustomerSelectionState();
}

class _Step1CustomerSelectionState
    extends ConsumerState<_Step1CustomerSelection> {
  final _customerRepository = CustomerRepository();
  final _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      _allCustomers = await _customerRepository.getAllCustomers();
      _filteredCustomers = _allCustomers;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _filteredCustomers = _allCustomers;
    } else {
      final q = query.toLowerCase();
      _filteredCustomers = _allCustomers.where((c) {
        return c.shopName.toLowerCase().contains(q) ||
            c.ownerName.toLowerCase().contains(q) ||
            c.phone.contains(q);
      }).toList();
    }
    setState(() {});
  }

  void _selectCustomer(Customer customer) {
    setState(() => _selectedCustomer = customer);
    ref.read(orderNotifierProvider.notifier).setCustomer(customer);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(orderNotifierProvider);
    final currentCustomer = draft.customer;

    // Update selection if changed via provider
    if (currentCustomer != null && currentCustomer != _selectedCustomer) {
      _selectedCustomer = currentCustomer;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search customer by name or phone...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        if (_selectedCustomer != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withAlpha((0.3 * 255).round())),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!.shopName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedCustomer!.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCustomer = null);
                    ref.read(orderNotifierProvider.notifier).reset();
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCustomers.isEmpty
              ? const Center(child: Text('No customers found'))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = _filteredCustomers[index];
              final isSelected =
                  _selectedCustomer?.id == customer.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected
                    ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha((0.1 * 255).round()),
                    child: Text(
                      customer.shopName.isNotEmpty
                          ? customer.shopName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    customer.shopName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                      '${customer.ownerName} • ${customer.phone}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                      color: Colors.green)
                      : null,
                  onTap: () => _selectCustomer(customer),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _selectedCustomer != null ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue to Products'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// STEP 2: Add Products
class _Step2AddProducts extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const _Step2AddProducts({required this.onNext, required this.onBack});

  @override
  ConsumerState<_Step2AddProducts> createState() => _Step2AddProductsState();
}

class _Step2AddProductsState extends ConsumerState<_Step2AddProducts> {
  final _orderRepository = OrderRepository();
  final _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _orderRepository.searchProducts(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _BarcodeScannerScreen()),
    );
    if (barcode != null && barcode.isNotEmpty && barcode != '-1') {
      final product = await _orderRepository.getProductByBarcode(barcode);
      if (mounted) {
        if (product != null) {
          if (product.stock > 0) {
            ref.read(orderNotifierProvider.notifier).addItem(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added: ${product.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product is out of stock'),
                backgroundColor: Colors.red,
              ),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(orderNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search product...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: _searchProducts,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        if (_searchResults.isNotEmpty && !_isSearching)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                final inCart = draft.items.any(
                        (item) => item.product.id == product.id);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha((0.1 * 255).round()),
                    child: const Icon(Icons.inventory_2),
                  ),
                  title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(0)} • Stock: ${product.stock}',
                  ),
                  trailing: inCart
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline),
                  onTap: () {
                    if (product.stock > 0) {
                      ref
                          .read(orderNotifierProvider.notifier)
                          .addItem(product);
                      _searchController.clear();
                      setState(() => _searchResults = []);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added: ${product.name}'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Out of stock'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Cart Items (${draft.items.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${AppConstants.currencySymbol}${draft.subtotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: draft.items.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No items in cart'),
                const SizedBox(height: 8),
                Text(
                  'Search or scan barcode to add products',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: draft.items.length,
            itemBuilder: (context, index) {
              final cartItem = draft.items[index];
              return _buildCartItemCard(context, cartItem);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: draft.items.isEmpty ? null : widget.onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue to Summary'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem cartItem) {
    final product = cartItem.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(0)} × ${cartItem.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${cartItem.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Stock: ${product.stock} ${product.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: product.stock > 5
                        ? Colors.green
                        : product.stock > 0
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ref
                        .read(orderNotifierProvider.notifier)
                        .updateItemQuantity(product.id!, cartItem.quantity - 1);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: cartItem.quantity < product.stock
                      ? () {
                    ref
                        .read(orderNotifierProvider.notifier)
                        .updateItemQuantity(
                        product.id!, cartItem.quantity + 1);
                  }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  onPressed: () {
                    ref
                        .read(orderNotifierProvider.notifier)
                        .removeItem(product.id!);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

// STEP 3: Order Summary
class _Step3OrderSummary extends ConsumerWidget {
  final VoidCallback onBack;
  final Function() onSave;
  const _Step3OrderSummary({required this.onBack, required this.onSave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderNotifierProvider);

    final discountController = TextEditingController(text: draft.discount.toStringAsFixed(0));
    final taxController = TextEditingController(text: draft.tax.toStringAsFixed(0));
    final paidController = TextEditingController(text: draft.paidAmount.toStringAsFixed(0));
    final notesController = TextEditingController(text: draft.notes);

    // Update controllers when draft changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        discountController.value = TextEditingValue(
          text: draft.discount.toStringAsFixed(0),
          selection: TextSelection.collapsed(offset: draft.discount.toStringAsFixed(0).length),
        );
        taxController.value = TextEditingValue(
          text: draft.tax.toStringAsFixed(0),
          selection: TextSelection.collapsed(offset: draft.tax.toStringAsFixed(0).length),
        );
        paidController.value = TextEditingValue(
          text: draft.paidAmount.toStringAsFixed(0),
          selection: TextSelection.collapsed(offset: draft.paidAmount.toStringAsFixed(0).length),
        );
        notesController.value = TextEditingValue(
          text: draft.notes,
          selection: TextSelection.collapsed(offset: draft.notes.length),
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerCard(context, draft),
          const SizedBox(height: 16),
          _buildItemsSummary(context, draft),
          const SizedBox(height: 16),
          _buildDiscountTaxSection(
            context,
            draft,
            discountController,
            taxController,
            ref,
          ),
          const SizedBox(height: 16),
          _buildPaymentSection(
            context,
            draft,
            paidController,
            ref,
          ),
          const SizedBox(height: 16),
          _buildNotesSection(context, notesController, ref),
          const SizedBox(height: 16),
          _buildGrandTotalCard(context, draft),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Consumer(
                    builder: (context, ref, child) {
                      final isSaving = ref.watch(isSavingProvider);
                      return ElevatedButton(
                        onPressed: isSaving ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Save Order'),
                      );
                    }
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, OrderDraft draft) {
    final customer = draft.customer;
    if (customer == null) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()),
              child: Text(
                customer.shopName.isNotEmpty
                    ? customer.shopName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    customer.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(customer.phone,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSummary(BuildContext context, OrderDraft draft) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items (${draft.items.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...draft.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('×${item.quantity}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Text(
                    '${AppConstants.currencySymbol}${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${AppConstants.currencySymbol}${draft.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountTaxSection(
      BuildContext context,
      OrderDraft draft,
      TextEditingController discountController,
      TextEditingController taxController,
      WidgetRef ref,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discount & Tax',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount',
                      suffixText: '%',
                      prefixIcon: Icon(Icons.local_offer),
                    ),
                    onChanged: (value) {
                      final discount = double.tryParse(value) ?? 0.0;
                      ref.read(orderNotifierProvider.notifier).setDiscount(discount);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: taxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tax',
                      suffixText: '%',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    onChanged: (value) {
                      final tax = double.tryParse(value) ?? 0.0;
                      ref.read(orderNotifierProvider.notifier).setTax(tax);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount Amount',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '-${AppConstants.currencySymbol}${draft.discountAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax Amount',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '+${AppConstants.currencySymbol}${draft.taxAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(
      BuildContext context,
      OrderDraft draft,
      TextEditingController paidController,
      WidgetRef ref,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(
                  value: PaymentMethod.cash,
                  label: Text('Cash'),
                  icon: Icon(Icons.money),
                ),
                ButtonSegment(
                  value: PaymentMethod.credit,
                  label: Text('Credit'),
                  icon: Icon(Icons.credit_card),
                ),
                ButtonSegment(
                  value: PaymentMethod.bankTransfer,
                  label: Text('Partial'),
                  icon: Icon(Icons.account_balance),
                ),
              ],
              selected: {draft.paymentMethod},
              onSelectionChanged: (selected) {
                ref
                    .read(orderNotifierProvider.notifier)
                    .setPaymentMethod(selected.first);
                if (selected.first == PaymentMethod.cash) {
                  paidController.text = draft.grandTotal.toStringAsFixed(0);
                } else if (selected.first == PaymentMethod.credit) {
                  paidController.text = '0';
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paidController,
              keyboardType: TextInputType.number,
              enabled: draft.paymentMethod == PaymentMethod.bankTransfer,
              decoration: InputDecoration(
                labelText: 'Paid Amount',
                prefixText: '${AppConstants.currencySymbol} ',
                prefixIcon: const Icon(Icons.attach_money),
                helperText: draft.paymentMethod == PaymentMethod.cash
                    ? 'Full payment'
                    : draft.paymentMethod == PaymentMethod.credit
                    ? 'No payment now'
                    : 'Enter partial payment amount',
              ),
              onChanged: (value) {
                final paid = double.tryParse(value) ?? 0.0;
                ref.read(orderNotifierProvider.notifier).setPaidAmount(paid);
              },
            ),
            if (draft.remainingAmount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha((0.3 * 255).round())),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining (Credit)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${AppConstants.currencySymbol}${draft.remainingAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(
      BuildContext context,
      TextEditingController notesController,
      WidgetRef ref,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add order notes (optional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                ref.read(orderNotifierProvider.notifier).setNotes(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(BuildContext context, OrderDraft draft) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha((0.8 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              Text(
                '${AppConstants.currencySymbol}${draft.grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paid',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                '${AppConstants.currencySymbol}${draft.paidAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remaining',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                '${AppConstants.currencySymbol}${draft.remainingAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: draft.remainingAmount > 0
                      ? Colors.yellow
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Provider to track saving state
final isSavingProvider = StateProvider<bool>((ref) => false);