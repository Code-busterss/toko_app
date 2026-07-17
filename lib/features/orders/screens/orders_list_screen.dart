// lib/features/orders/screens/orders_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/orders/models/order_with_customer.dart';
import 'package:toko_app/features/orders/screens/invoice_preview_screen.dart';
import '../../../core/constants/constants.dart';
import '../providers/orders_list_notifier.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersListNotifierProvider);

    // Listen for messages
    ref.listen<OrdersListState>(ordersListNotifierProvider, (previous, next) {
      if (next.actionMessage != null &&
          next.actionMessage != previous?.actionMessage) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.actionMessage!),
              backgroundColor:
                  next.isActionError ? Colors.red : Colors.green,
            ),
          );
        ref.read(ordersListNotifierProvider.notifier).clearMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(ordersListNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsSection(context, ref, state),
          _buildFilterChips(context, ref, state),
          _buildSearchBar(context, ref, state),
          Expanded(child: _buildOrdersList(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
      BuildContext context, WidgetRef ref, OrdersListState state) {
    return state.stats.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (stats) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.receipt_long,
                label: "Today's Orders",
                value: '${stats.todayOrdersCount}',
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.white24,
            ),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.attach_money,
                label: "Today's Amount",
                value:
                    '${AppConstants.currencySymbol}${stats.todayTotalAmount.toStringAsFixed(0)}',
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.white24,
            ),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.pending_actions,
                label: 'Pending',
                value:
                    '${AppConstants.currencySymbol}${stats.totalPendingAmount.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
      BuildContext context, WidgetRef ref, OrdersListState state) {
    final filters = [
      (OrderFilterStatus.all, 'All', Icons.list),
      (OrderFilterStatus.pending, 'Pending', Icons.pending),
      (OrderFilterStatus.paid, 'Paid', Icons.check_circle),
      (OrderFilterStatus.partial, 'Partial/Unpaid', Icons.warning),
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final (status, label, icon) = filters[index];
          final isSelected = state.filter.status == status;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(label),
              avatar: Icon(icon, size: 18),
              onSelected: (_) {
                ref
                    .read(ordersListNotifierProvider.notifier)
                    .setFilter(status);
              },
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, WidgetRef ref, OrdersListState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by invoice or customer name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: state.filter.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref
                        .read(ordersListNotifierProvider.notifier)
                        .setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          ref
              .read(ordersListNotifierProvider.notifier)
              .setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildOrdersList(
      BuildContext context, WidgetRef ref, OrdersListState state) {
    return state.orders.when(
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
                ref.read(ordersListNotifierProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(context, ref, state);
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(ordersListNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderWithCustomer = orders[index];
              return _OrderCard(
                orderWithCustomer: orderWithCustomer,
                isProcessing:
                    state.processingOrderId == orderWithCustomer.order.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context,
      WidgetRef ref,
      OrdersListState state,
      ) {
    final hasFilter = state.filter.status != OrderFilterStatus.all ||
        state.filter.searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No orders match your filter' : 'No orders yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                final notifier =
                    ref.read(ordersListNotifierProvider.notifier);
                notifier.setFilter(OrderFilterStatus.all);
                notifier.setSearchQuery('');
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderWithCustomer orderWithCustomer;
  final bool isProcessing;

  const _OrderCard({
    required this.orderWithCustomer,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = orderWithCustomer.order;
    final paymentStatus = orderWithCustomer.paymentStatus;
    final statusColor = _getPaymentStatusColor(paymentStatus);
    final statusLabel = _getPaymentStatusLabel(paymentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: isProcessing
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        InvoicePreviewScreen(order: order),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                orderWithCustomer.customerName,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPaymentStatusIcon(paymentStatus),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.dateTimeFormat.format(order.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      if (paymentStatus != PaymentStatus.paid)
                        Text(
                          'Remaining: ${AppConstants.currencySymbol}${orderWithCustomer.remainingAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${order.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid: ${AppConstants.currencySymbol}${order.paidAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              if (paymentStatus != PaymentStatus.paid) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () => _showCancelDialog(context, ref),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final confirmed = await _showMarkPaidDialog(
                                    context);
                                if (confirmed == true && context.mounted) {
                                  await ref
                                      .read(ordersListNotifierProvider.notifier)
                                      .markAsPaid(orderWithCustomer);
                                }
                              },
                        icon: isProcessing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle, size: 16),
                        label: const Text('Mark as Paid'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showMarkPaidDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Mark order ${orderWithCustomer.order.invoiceNumber} as fully paid?\n\n'
          'Amount: ${AppConstants.currencySymbol}${orderWithCustomer.order.totalAmount.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
          'Are you sure you want to cancel order ${orderWithCustomer.order.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(ordersListNotifierProvider.notifier)
                  .deleteOrder(orderWithCustomer.order.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.partial:
        return Colors.orange;
      case PaymentStatus.unpaid:
        return Colors.red;
    }
  }

  String _getPaymentStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'PAID';
      case PaymentStatus.partial:
        return 'PARTIAL';
      case PaymentStatus.unpaid:
        return 'UNPAID';
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.partial:
        return Icons.hourglass_top;
      case PaymentStatus.unpaid:
        return Icons.cancel;
    }
  }
}
