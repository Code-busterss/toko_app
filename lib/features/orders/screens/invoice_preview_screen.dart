// lib/features/orders/screens/invoice_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/customers/repositories/customer_repository.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/orders/providers/invoice_notifier.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final Order order;

  const InvoicePreviewScreen({super.key, required this.order});

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  final CustomerRepository _customerRepository = CustomerRepository();
  Customer? _customer;
  bool _isLoadingCustomer = true;

  // Company info (can be moved to settings later)
  final String _companyName = AppConstants.appName;
  final String _companyAddress = 'Your Company Address, City';
  final String _companyPhone = '+62 812-3456-7890';

  @override
  void initState() {
    super.initState();
    _loadCustomer();
    Future.microtask(() {
      ref.read(invoiceNotifierProvider.notifier).generateInvoice(
            order: widget.order,
            companyName: _companyName,
            companyAddress: _companyAddress,
            companyPhone: _companyPhone,
          );
    });
  }

  Future<void> _loadCustomer() async {
    try {
      final customer = await _customerRepository.getCustomerById(
        widget.order.customerId,
      );
      if (mounted) {
        setState(() {
          _customer = customer;
          _isLoadingCustomer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCustomer = false);
      }
    }
  }

  String get _pdfFileName =>
      'Invoice_${widget.order.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceNotifierProvider);

    // Listen for messages
    ref.listen<InvoiceState>(invoiceNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showSnackBar(next.errorMessage!, isError: true);
        ref.read(invoiceNotifierProvider.notifier).clearMessages();
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        _showSnackBar(next.successMessage!);
        ref.read(invoiceNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          if (invoiceState.document != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'print':
                    ref
                        .read(invoiceNotifierProvider.notifier)
                        .printInvoice(_pdfFileName);
                    break;
                  case 'save':
                    ref
                        .read(invoiceNotifierProvider.notifier)
                        .savePdf(_pdfFileName);
                    break;
                  case 'share':
                    ref
                        .read(invoiceNotifierProvider.notifier)
                        .sharePdf(_pdfFileName);
                    break;
                  case 'whatsapp':
                    if (_customer != null) {
                      ref
                          .read(invoiceNotifierProvider.notifier)
                          .shareViaWhatsApp(
                            order: widget.order,
                            customer: _customer!,
                            fileName: _pdfFileName,
                          );
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 20),
                      SizedBox(width: 8),
                      Text('Print'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text('Save PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'whatsapp',
                  child: Row(
                    children: [
                      Icon(Icons.chat, size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Share via WhatsApp'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoadingCustomer
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
              ? const Center(child: Text('Customer not found'))
              : invoiceState.isGenerating
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating invoice...'),
                        ],
                      ),
                    )
                  : invoiceState.document == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              const Text('Failed to generate invoice'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(invoiceNotifierProvider.notifier)
                                      .generateInvoice(
                                        order: widget.order,
                                        companyName: _companyName,
                                        companyAddress: _companyAddress,
                                        companyPhone: _companyPhone,
                                      );
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _buildInvoicePreview(context),
      bottomNavigationBar: invoiceState.document != null
          ? _buildActionBar(context, invoiceState)
          : null,
    );
  }

  Widget _buildInvoicePreview(BuildContext context) {
    final order = widget.order;
    final customer = _customer!;
    final subtotal = order.items.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
    final remaining = order.totalAmount - order.paidAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header
          _buildCompanyHeader(context),
          const SizedBox(height: 20),

          // Invoice Info
          _buildInvoiceInfoCard(context, order),
          const SizedBox(height: 16),

          // Customer Info
          _buildCustomerInfoCard(context, customer),
          const SizedBox(height: 20),

          // Items Table
          _buildItemsTable(context, order),
          const SizedBox(height: 16),

          // Totals
          _buildTotalsCard(
            context,
            subtotal: subtotal,
            discount: order.discount,
            tax: order.tax,
            total: order.totalAmount,
            paid: order.paidAmount,
            remaining: remaining,
          ),
          const SizedBox(height: 20),

          // Notes
          if (order.notes != null && order.notes!.isNotEmpty)
            _buildNotesCard(context, order.notes!),

          const SizedBox(height: 16),

          // Footer
          Center(
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Thank you for your business!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is a computer-generated invoice.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'T',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _companyName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                _companyAddress,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Phone: $_companyPhone',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          'INVOICE',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildInvoiceInfoCard(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoField(
              context,
              label: 'Invoice Number',
              value: order.invoiceNumber,
            ),
          ),
          Expanded(
            child: _buildInfoField(
              context,
              label: 'Date',
              value: AppConstants.dateFormat.format(order.date),
            ),
          ),
          Expanded(
            child: _buildInfoField(
              context,
              label: 'Status',
              value: order.status.name.toUpperCase(),
              valueColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context, Customer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bill To:',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.shopName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(customer.ownerName,
                  style: Theme.of(context).textTheme.bodySmall),
              Text(customer.phone,
                  style: Theme.of(context).textTheme.bodySmall),
              if (customer.address != null && customer.address!.isNotEmpty)
                Text(customer.address!,
                    style: Theme.of(context).textTheme.bodySmall),
              if (customer.city != null && customer.city!.isNotEmpty)
                Text(customer.city!,
                    style: Theme.of(context).textTheme.bodySmall),
              if (customer.email != null && customer.email!.isNotEmpty)
                Text(customer.email!,
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context, Order order) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 50,
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: const Text(
                    'Rate',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: index.isOdd
                    ? Colors.grey.shade50
                    : Colors.transparent,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${item.qty}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${AppConstants.currencySymbol}${item.rate.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      '${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(
    BuildContext context, {
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required double paid,
    required double remaining,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildTotalRow(context, 'Subtotal', subtotal),
            if (discount > 0)
              _buildTotalRow(
                context,
                'Discount',
                -discount,
                valueColor: Colors.red,
              ),
            if (tax > 0) _buildTotalRow(context, 'Tax', tax),
            const Divider(),
            _buildTotalRow(
              context,
              'Grand Total',
              total,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              valueStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            _buildTotalRow(context, 'Paid', paid, valueColor: Colors.green),
            const Divider(),
            _buildTotalRow(
              context,
              'Remaining',
              remaining,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              valueStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: remaining > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    double value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    final prefix = value < 0 ? '-' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(
            '$prefix${AppConstants.currencySymbol}${value.abs().toStringAsFixed(0)}',
            style: valueStyle ??
                TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notes,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, InvoiceState invoiceState) {
    final hasAnyAction = invoiceState.currentAction != null;

    return Container(
      padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasAnyAction
                    ? null
                    : () => ref
                        .read(invoiceNotifierProvider.notifier)
                        .printInvoice(_pdfFileName),
                icon: hasAnyAction &&
                        invoiceState.currentAction == InvoiceActionType.printing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                label: const Text('Print'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasAnyAction
                    ? null
                    : () => ref
                        .read(invoiceNotifierProvider.notifier)
                        .savePdf(_pdfFileName),
                icon: hasAnyAction &&
                        invoiceState.currentAction == InvoiceActionType.saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasAnyAction
                    ? null
                    : () => ref
                        .read(invoiceNotifierProvider.notifier)
                        .sharePdf(_pdfFileName),
                icon: hasAnyAction &&
                        invoiceState.currentAction == InvoiceActionType.sharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasAnyAction || _customer == null
                    ? null
                    : () => ref
                        .read(invoiceNotifierProvider.notifier)
                        .shareViaWhatsApp(
                          order: widget.order,
                          customer: _customer!,
                          fileName: _pdfFileName,
                        ),
                icon: hasAnyAction &&
                        invoiceState.currentAction ==
                            InvoiceActionType.whatsapp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to use asMap on List
extension _ListExtension<T> on List<T> {
  Iterable<MapEntry<int, T>> asMap() => asMapIterable();
  Iterable<MapEntry<int, T>> asMapIterable() sync* {
    for (int i = 0; i < length; i++) {
      yield MapEntry(i, this[i]);
    }
  }
}
