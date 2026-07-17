// lib/features/customers/screens/customer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/customers/repositories/customer_repository.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/payments/models/payment_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

import '../../payments/screens/credit_ledger_screen.dart';
import '../../payments/screens/receive_payment_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  final _repository = CustomerRepository();
  late TabController _tabController;
  Customer? _customer;
  CustomerStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customer =
          await _repository.getCustomerById(widget.customerId);
      final stats = await _repository.getCustomerStats(widget.customerId);

      if (mounted) {
        setState(() {
          _customer = customer;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Not Found')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final customer = _customer!;
    final stats = _stats!;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.shopName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCustomerInfoCard(context, customer),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreditLedgerScreen(
                            customerId: widget.customerId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ledger'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceivePaymentScreen(
                            initialCustomerId: widget.customerId,
                          ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadData();
                        }
                      });
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Receive Payment'),
                  ),
                ),
              ],
            ),
          ),
          _buildStatsCards(context, stats),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Orders'),
              Tab(text: 'Payments'),
              Tab(text: 'Pending'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OrderHistoryTab(customerId: widget.customerId),
                _PaymentHistoryTab(customerId: widget.customerId),
                _PendingBillsTab(customerId: widget.customerId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context, Customer customer) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  customer.shopName.isNotEmpty
                      ? customer.shopName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.ownerName,
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
          _buildInfoRow(Icons.phone, customer.phone),
          if (customer.whatsapp != null && customer.whatsapp!.isNotEmpty)
            _buildInfoRow(Icons.chat, 'WhatsApp: ${customer.whatsapp}'),
          if (customer.email != null && customer.email!.isNotEmpty)
            _buildInfoRow(Icons.email, customer.email!),
          if (customer.address != null && customer.address!.isNotEmpty)
            _buildInfoRow(Icons.location_on, customer.address!),
          if (customer.city != null && customer.city!.isNotEmpty)
            _buildInfoRow(Icons.location_city, customer.city!),
          if (customer.creditLimit > 0)
            _buildInfoRow(
              Icons.account_balance_wallet,
              'Credit Limit: ${AppConstants.currencySymbol} ${customer.creditLimit.toStringAsFixed(0)}',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, CustomerStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.shopping_bag,
              label: 'Orders',
              value: '${stats.totalOrders}',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.check_circle,
              label: 'Paid',
              value: '${AppConstants.currencySymbol}${stats.totalPaid.toStringAsFixed(0)}',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.pending,
              label: 'Remaining',
              value: '${AppConstants.currencySymbol}${stats.remainingBalance.toStringAsFixed(0)}',
              color: stats.remainingBalance > 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// Order History Tab
class _OrderHistoryTab extends StatelessWidget {
  final int customerId;
  const _OrderHistoryTab({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: CustomerRepository().getCustomerOrders(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No orders yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderItem(context, order);
          },
        );
      },
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order) {
    final statusColor = _getStatusColor(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.receipt_long, color: statusColor),
        ),
        title: Text(
          order.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(AppConstants.dateFormat.format(order.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppConstants.currencySymbol} ${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

// Payment History Tab
class _PaymentHistoryTab extends StatelessWidget {
  final int customerId;
  const _PaymentHistoryTab({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: CustomerRepository().getCustomerPayments(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No payments yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentItem(context, payment);
          },
        );
      },
    );
  }

  Widget _buildPaymentItem(BuildContext context, Payment payment) {
    final isIncoming = payment.type == PaymentType.incoming;
    final color = isIncoming ? Colors.green : Colors.red;
    final icon = isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    final label = isIncoming ? 'Received' : 'Refund';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(AppConstants.dateFormat.format(payment.date)),
        trailing: Text(
          '${isIncoming ? '+' : '-'}${AppConstants.currencySymbol} ${payment.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}

// Pending Bills Tab
class _PendingBillsTab extends StatelessWidget {
  final int customerId;
  const _PendingBillsTab({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: CustomerRepository().getCustomerPendingBills(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No pending bills',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 4),
                Text('All payments are up to date'),
              ],
            ),
          );
        }

        double totalPending = 0;
        for (final order in orders) {
          totalPending += order.totalAmount - order.paidAmount;
        }

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pending',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${orders.length} bill(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    '${AppConstants.currencySymbol} ${totalPending.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildPendingBillItem(context, order);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingBillItem(BuildContext context, Order order) {
    final pending = order.totalAmount - order.paidAmount;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  AppConstants.dateFormat.format(order.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${AppConstants.currencySymbol} ${order.totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Paid: ${AppConstants.currencySymbol} ${order.paidAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Pending',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      '${AppConstants.currencySymbol} ${pending.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
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
