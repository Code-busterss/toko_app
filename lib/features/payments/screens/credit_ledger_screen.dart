// lib/features/payments/screens/credit_ledger_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/payments/providers/credit_ledger_notifier.dart';
import 'package:toko_app/features/payments/repositories/payment_repository.dart';

class CreditLedgerScreen extends ConsumerStatefulWidget {
  final int customerId;
  const CreditLedgerScreen({super.key, required this.customerId});

  @override
  ConsumerState<CreditLedgerScreen> createState() => _CreditLedgerScreenState();
}

class _CreditLedgerScreenState extends ConsumerState<CreditLedgerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(creditLedgerNotifierProvider.notifier)
          .loadCustomer(widget.customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creditLedgerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.customer?.shopName ?? 'Credit Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(creditLedgerNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: state.customer == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCustomerHeader(context, state),
                _buildStatsRow(context, state),
                const SizedBox(height: 8),
                Expanded(child: _buildLedgerList(context, state)),
              ],
            ),
    );
  }

  Widget _buildCustomerHeader(BuildContext context, CreditLedgerState state) {
    final customer = state.customer!;
    final balanceColor =
        state.currentBalance > 0 ? Colors.red : state.currentBalance < 0 ? Colors.green : Colors.grey;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            balanceColor,
            balanceColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  customer.shopName.isNotEmpty
                      ? customer.shopName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      customer.phone,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          const Text(
            'Current Balance',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppConstants.currencySymbol}${state.currentBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            state.currentBalance > 0
                ? 'Customer owes you'
                : state.currentBalance < 0
                    ? 'You owe customer'
                    : 'Settled',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, CreditLedgerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              label: 'Total Debit',
              value:
                  '${AppConstants.currencySymbol}${state.totalDebit.toStringAsFixed(0)}',
              color: Colors.red,
              icon: Icons.arrow_upward,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              label: 'Total Credit',
              value:
                  '${AppConstants.currencySymbol}${state.totalCredit.toStringAsFixed(0)}',
              color: Colors.green,
              icon: Icons.arrow_downward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerList(BuildContext context, CreditLedgerState state) {
    return state.entries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(creditLedgerNotifierProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No ledger entries'),
              ],
            ),
          );
        }

        // Reverse to show newest first
        final reversedEntries = entries.reversed.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reversedEntries.length,
          itemBuilder: (context, index) {
            final entry = reversedEntries[index];
            return _buildLedgerEntry(context, entry);
          },
        );
      },
    );
  }

  Widget _buildLedgerEntry(BuildContext context, LedgerEntry entry) {
    final isOrder = entry.isOrder;
    final isPayment = entry.isPayment;
    final isOpening = entry.type == 'opening';

    Color color;
    IconData icon;
    if (isOpening) {
      color = Colors.blue;
      icon = Icons.account_balance_wallet;
    } else if (isOrder) {
      color = Colors.red;
      icon = Icons.receipt_long;
    } else {
      color = Colors.green;
      icon = Icons.payment;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.type == 'opening'
                            ? 'Opening Balance'
                            : AppConstants.dateTimeFormat.format(entry.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        entry.reference,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (entry.debit > 0)
                      Text(
                        '+${AppConstants.currencySymbol}${entry.debit.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (entry.credit > 0)
                      Text(
                        '-${AppConstants.currencySymbol}${entry.credit.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: entry.runningBalance > 0
                            ? Colors.red.withOpacity(0.1)
                            : entry.runningBalance < 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bal: ${AppConstants.currencySymbol}${entry.runningBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: entry.runningBalance > 0
                              ? Colors.red
                              : entry.runningBalance < 0
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
