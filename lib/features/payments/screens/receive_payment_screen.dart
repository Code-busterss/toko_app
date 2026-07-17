// lib/features/payments/screens/receive_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/core/services/payment_receipt_service.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/payments/providers/payment_notifier.dart';
import 'package:toko_app/features/payments/repositories/payment_repository.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class ReceivePaymentScreen extends ConsumerStatefulWidget {
  final int? initialCustomerId;
  const ReceivePaymentScreen({super.key, this.initialCustomerId});

  @override
  ConsumerState<ReceivePaymentScreen> createState() =>
      _ReceivePaymentScreenState();
}

class _ReceivePaymentScreenState extends ConsumerState<ReceivePaymentScreen> {
  int _currentStep = 0;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _paymentReceiptService = PaymentReceiptService();

  // Company info
  final String _companyName = AppConstants.appName;
  final String _companyAddress = 'Your Company Address, City';
  final String _companyPhone = '+62 812-3456-7890';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(receivePaymentNotifierProvider.notifier).reset();
      if (widget.initialCustomerId != null) {
        final customers =
            ref.read(receivePaymentNotifierProvider).allCustomers;
        if (customers.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        final updatedCustomers =
            ref.read(receivePaymentNotifierProvider).allCustomers;
        final customer = updatedCustomers.firstWhere(
          (c) => c.id == widget.initialCustomerId,
          orElse: () => updatedCustomers.first,
        );
        await ref
            .read(receivePaymentNotifierProvider.notifier)
            .selectCustomer(customer);
        _currentStep = 1;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
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

  Future<void> _savePayment() async {
    ref
        .read(receivePaymentNotifierProvider.notifier)
        .setNotes(_notesController.text);

    final paymentId = await ref
        .read(receivePaymentNotifierProvider.notifier)
        .savePayment();

    if (paymentId != null && mounted) {
      _showSuccessDialog(paymentId);
    }
  }

  Future<void> _showSuccessDialog(int paymentId) async {
    final state = ref.read(receivePaymentNotifierProvider);
    final customer = state.selectedCustomer!;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Payment Recorded'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt: PAY-$paymentId'),
            const SizedBox(height: 4),
            Text(
              'Amount: ${AppConstants.currencySymbol}${state.paymentAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('From: ${customer.shopName}'),
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
              await _generateAndShowReceipt(paymentId);
            },
            icon: const Icon(Icons.receipt),
            label: const Text('View Receipt'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndShowReceipt(int paymentId) async {
    final state = ref.read(receivePaymentNotifierProvider);
    final customer = state.selectedCustomer!;

    // Fetch the saved payment
    final payments =
        await PaymentRepository().getCustomerPayments(customer.id!);
    final payment = payments.firstWhere((p) => p.id == paymentId);

    // Get linked orders (those that were selected)
    final linkedOrders = state.unpaidOrders
        .where((o) => state.selectedOrderIds.contains(o.id))
        .toList();

    final previousBalance =
        state.outstandingBalance + state.paymentAmount;

    final doc = await _paymentReceiptService.generateReceiptPdf(
      payment: payment,
      customer: customer,
      linkedOrders: linkedOrders,
      previousBalance: previousBalance,
      companyName: _companyName,
      companyAddress: _companyAddress,
      companyPhone: _companyPhone,
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Receipt'),
        content: const Text('Receipt generated successfully. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _paymentReceiptService.printReceipt(doc);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final fileName =
                  'Receipt_PAY-${paymentId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
              final path =
                  await _paymentReceiptService.saveReceipt(doc, fileName);
              if (mounted) {
                await _paymentReceiptService.shareReceipt(path);
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    ref.listen<ReceivePaymentState>(receivePaymentNotifierProvider,
        (previous, next) {
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
        ref.read(receivePaymentNotifierProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        ref.read(receivePaymentNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Payment'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Payment?'),
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
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
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
          _Step1CustomerSelection(
            searchController: _searchController,
            onNext: _nextStep,
          ),
          _Step2SelectOrders(
            onNext: _nextStep,
            onBack: _previousStep,
          ),
          _Step3PaymentDetails(
            amountController: _amountController,
            notesController: _notesController,
            onBack: _previousStep,
            onSave: _savePayment,
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
          _buildStepDot(0, 'Customer'),
          _buildStepLine(0),
          _buildStepDot(1, 'Orders'),
          _buildStepLine(1),
          _buildStepDot(2, 'Payment'),
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

// STEP 1: Customer Selection
class _Step1CustomerSelection extends ConsumerWidget {
  final TextEditingController searchController;
  final VoidCallback onNext;

  const _Step1CustomerSelection({
    required this.searchController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receivePaymentNotifierProvider);
    final query = searchController.text.toLowerCase();

    final filteredCustomers = query.isEmpty
        ? state.allCustomers
        : state.allCustomers.where((c) {
            return c.shopName.toLowerCase().contains(query) ||
                c.ownerName.toLowerCase().contains(query) ||
                c.phone.contains(query);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search customer by name or phone...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            onChanged: (_) {
              // Trigger rebuild by using searchController.text in build
            },
          ),
        ),
        if (state.selectedCustomer != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha:0.3)),
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
                        state.selectedCustomer!.shopName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        state.selectedCustomer!.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(receivePaymentNotifierProvider.notifier)
                        .clearCustomer();
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.isLoadingCustomers
              ? const Center(child: CircularProgressIndicator())
              : filteredCustomers.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isSelected =
                            state.selectedCustomer?.id == customer.id;
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
                                      .withValues(alpha:0.1),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                                '${customer.ownerName} • ${customer.phone}'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                            onTap: () async {
                              await ref
                                  .read(receivePaymentNotifierProvider.notifier)
                                  .selectCustomer(customer);
                            },
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
              onPressed: state.selectedCustomer != null ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue to Orders'),
            ),
          ),
        ),
      ],
    );
  }
}

// STEP 2: Select Orders
class _Step2SelectOrders extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2SelectOrders({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receivePaymentNotifierProvider);
    final customer = state.selectedCustomer;

    if (customer == null) {
      return const Center(child: Text('No customer selected'));
    }

    return Column(
      children: [
        // Outstanding balance card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                state.outstandingBalance > 0 ? Colors.red : Colors.green,
                (state.outstandingBalance > 0 ? Colors.red : Colors.green)
                    .withValues(alpha:0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Outstanding Balance',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppConstants.currencySymbol}${state.outstandingBalance.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customer.shopName,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        // Orders header with select all
        if (state.unpaidOrders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Unpaid Orders (${state.unpaidOrders.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (state.selectedOrderIds.length ==
                        state.unpaidOrders.length) {
                      ref
                          .read(receivePaymentNotifierProvider.notifier)
                          .clearOrderSelection();
                    } else {
                      ref
                          .read(receivePaymentNotifierProvider.notifier)
                          .selectAllOrders();
                    }
                  },
                  child: Text(
                    state.selectedOrderIds.length ==
                            state.unpaidOrders.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: state.unpaidOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text('No unpaid orders'),
                      const SizedBox(height: 8),
                      Text(
                        'Customer has no outstanding orders',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.unpaidOrders.length,
                  itemBuilder: (context, index) {
                    final order = state.unpaidOrders[index];
                    final isSelected =
                        state.selectedOrderIds.contains(order.id);
                    return _buildOrderCard(
                        context, ref, order, isSelected);
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
                  child: ElevatedButton(
                    onPressed: state.selectedOrderIds.isNotEmpty ||
                            state.outstandingBalance > 0
                        ? onNext
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      state.selectedOrderIds.isEmpty
                          ? 'Continue (General Payment)'
                          : 'Continue to Payment',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Order order,
      bool isSelected) {
    final outstanding = order.totalAmount - order.paidAmount;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha:0.3)
          : null,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) {
          ref
              .read(receivePaymentNotifierProvider.notifier)
              .toggleOrderSelection(order.id!);
        },
        title: Text(
          order.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              AppConstants.dateFormat.format(order.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Total: ${AppConstants.currencySymbol}${order.totalAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Text(
                  'Paid: ${AppConstants.currencySymbol}${order.paidAmount.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        secondary: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Due', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
              '${AppConstants.currencySymbol}${outstanding.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

// STEP 3: Payment Details
class _Step3PaymentDetails extends ConsumerStatefulWidget {
  final TextEditingController amountController;
  final TextEditingController notesController;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const _Step3PaymentDetails({
    required this.amountController,
    required this.notesController,
    required this.onBack,
    required this.onSave,
  });

  @override
  ConsumerState<_Step3PaymentDetails> createState() =>
      _Step3PaymentDetailsState();
}

class _Step3PaymentDetailsState extends ConsumerState<_Step3PaymentDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(receivePaymentNotifierProvider);
      if (state.paymentAmount > 0) {
        widget.amountController.text =
            state.paymentAmount.toStringAsFixed(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receivePaymentNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer summary
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha:0.1),
                    child: Text(
                      state.selectedCustomer!.shopName.isNotEmpty
                          ? state.selectedCustomer!.shopName[0].toUpperCase()
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
                        Text(
                          state.selectedCustomer!.shopName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          state.selectedCustomer!.phone,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Outstanding',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        '${AppConstants.currencySymbol}${state.outstandingBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: state.outstandingBalance > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment amount
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Amount',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${AppConstants.currencySymbol} ',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixIcon: TextButton(
                        onPressed: () {
                          ref
                              .read(receivePaymentNotifierProvider.notifier)
                              .fillFullAmount();
                          widget.amountController.text = state
                              .outstandingBalance
                              .toStringAsFixed(0);
                        },
                        child: const Text('FULL'),
                      ),
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      ref
                          .read(receivePaymentNotifierProvider.notifier)
                          .setPaymentAmount(amount);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (state.paymentAmount > state.outstandingBalance)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Amount exceeds outstanding balance',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment method
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method',
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
                        value: PaymentMethod.bankTransfer,
                        label: Text('Bank'),
                        icon: Icon(Icons.account_balance),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.eWallet,
                        label: Text('E-Wallet'),
                        icon: Icon(Icons.wallet),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.qris,
                        label: Text('QRIS'),
                        icon: Icon(Icons.qr_code),
                      ),
                    ],
                    selected: {state.paymentMethod},
                    onSelectionChanged: (selected) {
                      ref
                          .read(receivePaymentNotifierProvider.notifier)
                          .setPaymentMethod(selected.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes (Optional)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add payment notes...',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Amount',
                        style: TextStyle(color: Colors.white70)),
                    Text(
                      '${AppConstants.currencySymbol}${state.paymentAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                    const Text('Remaining After Payment',
                        style: TextStyle(color: Colors.white70)),
                    Text(
                      '${AppConstants.currencySymbol}${(state.outstandingBalance - state.paymentAmount).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: state.outstandingBalance - state.paymentAmount > 0
                            ? Colors.yellow
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                  onPressed: state.isSaving ||
                          state.paymentAmount <= 0 ||
                          state.paymentAmount > state.outstandingBalance
                      ? null
                      : widget.onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Record Payment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
