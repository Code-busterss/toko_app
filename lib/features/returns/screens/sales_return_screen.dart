// lib/features/returns/screens/sales_return_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/returns/providers/return_notifier.dart';

class SalesReturnScreen extends ConsumerStatefulWidget {
  final int? initialOrderId;
  const SalesReturnScreen({super.key, this.initialOrderId});

  @override
  ConsumerState<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends ConsumerState<SalesReturnScreen> {
  int _currentStep = 0;
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(returnNotifierProvider.notifier).clearSelection();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitReturn() async {
    ref.read(returnNotifierProvider.notifier).setReason(_reasonController.text);

    final returnId =
        await ref.read(returnNotifierProvider.notifier).submitReturn();

    if (returnId != null && mounted) {
      _showSuccessDialog(returnId);
    }
  }

  void _showSuccessDialog(int returnId) {
    final state = ref.read(returnNotifierProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Return Processed')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Return ID: RET-$returnId'),
            const SizedBox(height: 8),
            Text(
              'Invoice: ${state.selectedOrder?.invoiceNumber ?? 'N/A'}',
            ),
            const SizedBox(height: 4),
            Text(
              'Amount: ${AppConstants.currencySymbol}${state.totalReturnAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock has been restored for returned items',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Customer balance has been adjusted',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnNotifierProvider);

    ref.listen<ReturnState>(returnNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        ref.read(returnNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Return'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Return?'),
                  content: const Text('All entered data will be lost.'),
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
          child: _buildStepIndicator(),
        ),
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          _Step1SelectOrder(
            searchController: _searchController,
            onNext: _nextStep,
          ),
          _Step2SelectItems(
            onNext: _nextStep,
            onBack: _previousStep,
          ),
          _Step3ConfirmReturn(
            reasonController: _reasonController,
            onBack: _previousStep,
            onSubmit: _submitReturn,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepDot(0, 'Order'),
          _buildStepLine(0),
          _buildStepDot(1, 'Items'),
          _buildStepLine(1),
          _buildStepDot(2, 'Confirm'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${step + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildStepLine(int afterStep) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: _currentStep > afterStep ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
}

// STEP 1: Select Order
class _Step1SelectOrder extends ConsumerWidget {
  final TextEditingController searchController;
  final VoidCallback onNext;

  const _Step1SelectOrder({
    required this.searchController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnNotifierProvider);
    final query = searchController.text.toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by invoice number or customer...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: (_) {},
          ),
        ),
        if (state.selectedOrder != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
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
                        state.selectedOrder!.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${state.customerName} • ${AppConstants.dateFormat.format(state.selectedOrder!.date)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(returnNotifierProvider.notifier).clearSelection();
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.orders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading orders: $e'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (orders) {
              final filtered = query.isEmpty
                  ? orders
                  : orders.where((o) {
                      final invoice =
                          (o['invoiceNumber'] as String?)?.toLowerCase() ?? '';
                      final customer =
                          (o['customerName'] as String?)?.toLowerCase() ?? '';
                      return invoice.contains(query) || customer.contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No orders found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final orderData = filtered[index];
                  final order = Order.fromMap(orderData);
                  final customerName =
                      orderData['customerName'] as String? ?? 'Unknown';
                  final isSelected =
                      state.selectedOrder?.id == order.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                        child: Icon(
                          Icons.receipt_long,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        order.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '$customerName • ${AppConstants.dateFormat.format(order.date)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${AppConstants.currencySymbol}${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${order.items.length} items',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () async {
                        await ref
                            .read(returnNotifierProvider.notifier)
                            .selectOrder(orderData);
                      },
                    ),
                  );
                },
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
              onPressed: state.selectedOrder != null ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue to Select Items'),
            ),
          ),
        ),
      ],
    );
  }
}

// STEP 2: Select Items to Return
class _Step2SelectItems extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2SelectItems({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnNotifierProvider);

    if (state.selectedOrder == null) {
      return const Center(child: Text('No order selected'));
    }

    return Column(
      children: [
        // Order info header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.selectedOrder!.invoiceNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${state.customerName} • ${AppConstants.dateFormat.format(state.selectedOrder!.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (state.alreadyReturnedAmount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Already returned: ${AppConstants.currencySymbol}${state.alreadyReturnedAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Select all / clear
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Select Items to Return',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  if (state.selectedItemsCount == state.returnItems.length) {
                    ref.read(returnNotifierProvider.notifier).clearAllItems();
                  } else {
                    ref.read(returnNotifierProvider.notifier).selectAllItems();
                  }
                },
                child: Text(
                  state.selectedItemsCount == state.returnItems.length
                      ? 'Clear All'
                      : 'Select All',
                ),
              ),
            ],
          ),
        ),
        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.returnItems.length,
            itemBuilder: (context, index) {
              final item = state.returnItems[index];
              return _buildReturnItemCard(context, ref, item, index);
            },
          ),
        ),
        // Bottom bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.selectedItemsCount} item(s) selected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Return Total: ${AppConstants.currencySymbol}${state.totalReturnAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed:
                            state.hasSelectedItems ? onNext : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Continue to Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnItemCard(
    BuildContext context,
    WidgetRef ref,
    SelectedReturnItem item,
    int index,
  ) {
    final isSelected = item.isSelected;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (value == true) {
                      ref
                          .read(returnNotifierProvider.notifier)
                          .updateItemQty(index, item.orderItem.qty);
                    } else {
                      ref
                          .read(returnNotifierProvider.notifier)
                          .updateItemQty(index, 0);
                    }
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.orderItem.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppConstants.currencySymbol}${item.orderItem.rate.toStringAsFixed(0)} x ${item.orderItem.qty}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${item.orderItem.total.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Return Qty:'),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: item.returnQty > 1
                        ? () => ref
                            .read(returnNotifierProvider.notifier)
                            .updateItemQty(index, item.returnQty - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 28,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.returnQty}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: item.returnQty < item.orderItem.qty
                        ? () => ref
                            .read(returnNotifierProvider.notifier)
                            .updateItemQty(index, item.returnQty + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 28,
                  ),
                  const Spacer(),
                  Text(
                    'Max: ${item.orderItem.qty}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${AppConstants.currencySymbol}${item.returnTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// STEP 3: Confirm Return
class _Step3ConfirmReturn extends ConsumerWidget {
  final TextEditingController reasonController;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _Step3ConfirmReturn({
    required this.reasonController,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnNotifierProvider);
    final selectedItems =
        state.returnItems.where((item) => item.isSelected).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original Order',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          state.selectedOrder!.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${state.customerName} • ${AppConstants.dateFormat.format(state.selectedOrder!.date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items to return
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items Being Returned (${selectedItems.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...selectedItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.keyboard_return,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.orderItem.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${item.returnQty} x ${AppConstants.currencySymbol}${item.orderItem.rate.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${AppConstants.currencySymbol}${item.returnTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reason
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason for Return *',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Why are these items being returned?\n(e.g., Damaged, Wrong product, Customer request...)',
                      prefixIcon: Icon(Icons.help_outline),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (value) {
                      ref.read(returnNotifierProvider.notifier).setReason(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  // Quick reason chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      'Damaged Product',
                      'Wrong Item',
                      'Quality Issue',
                      'Customer Request',
                      'Expired Product',
                    ].map((reason) => ActionChip(
                          label: Text(reason, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            reasonController.text = reason;
                            ref
                                .read(returnNotifierProvider.notifier)
                                .setReason(reason);
                          },
                        )).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Impact summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Return Impact',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildImpactRow(
                  Icons.inventory,
                  'Stock will be restored',
                  '${selectedItems.length} product(s)',
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildImpactRow(
                  Icons.account_balance_wallet,
                  'Customer balance will increase by',
                  '${AppConstants.currencySymbol}${state.totalReturnAmount.toStringAsFixed(0)}',
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildImpactRow(
                  Icons.payment,
                  'Order paid amount will decrease by',
                  '${AppConstants.currencySymbol}${state.totalReturnAmount.toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grand total card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade500],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Return Amount',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('To be refunded/adjusted',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                Text(
                  '${AppConstants.currencySymbol}${state.totalReturnAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isSaving ? null : onBack,
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
                  onPressed: state.isSaving || state.reason.trim().isEmpty
                      ? null
                      : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirm Return'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImpactRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
