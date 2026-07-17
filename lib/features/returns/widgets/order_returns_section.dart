// lib/features/returns/widgets/order_returns_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/returns/models/return_model.dart';
import 'package:toko_app/features/returns/providers/return_notifier.dart';
import 'package:toko_app/features/returns/screens/sales_return_screen.dart';

class OrderReturnsSection extends ConsumerWidget {
  final int orderId;
  const OrderReturnsSection({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(returnsByOrderProvider(orderId));

    return returnsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading returns: $e'),
      ),
      data: (returns) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Returns (${returns.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SalesReturnScreen(initialOrderId: orderId),
                        ),
                      ).then((_) {
                        ref.invalidate(returnsByOrderProvider(orderId));
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Return'),
                  ),
                ],
              ),
            ),
            if (returns.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No returns for this order',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...returns.map((ret) => _buildReturnCard(context, ret)),
          ],
        );
      },
    );
  }

  Widget _buildReturnCard(BuildContext context, SalesReturn ret) {
    final statusColor = _getStatusColor(ret.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  child: Icon(Icons.keyboard_return, color: statusColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RET-${ret.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        AppConstants.dateTimeFormat.format(ret.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ret.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...ret.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.productName} x ${item.returnQty}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.help_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Reason: ${ret.reason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (ret.stockRestored)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.green),
                            SizedBox(width: 2),
                            Text('Stock Restored', style: TextStyle(fontSize: 10, color: Colors.green)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 4),
                    if (ret.refundIssued)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 12, color: Colors.blue),
                            SizedBox(width: 2),
                            Text('Refund Issued', style: TextStyle(fontSize: 10, color: Colors.blue)),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  'Total: ${AppConstants.currencySymbol}${ret.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return Colors.orange;
      case ReturnStatus.approved:
        return Colors.blue;
      case ReturnStatus.completed:
        return Colors.green;
      case ReturnStatus.rejected:
        return Colors.red;
    }
  }
}
