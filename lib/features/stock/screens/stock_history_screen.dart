// lib/features/stock/screens/stock_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/stock/models/stock_adjustment_model.dart';
import 'package:toko_app/features/stock/providers/stock_notifier.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class StockHistoryScreen extends ConsumerStatefulWidget {
  final Product product;

  const StockHistoryScreen({super.key, required this.product});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(stockAdjustmentsNotifierProvider.notifier)
          .loadAdjustmentsByProductId(widget.product.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockAdjustmentsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Stock History - ${widget.product.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(stockAdjustmentsNotifierProvider.notifier)
                  .loadAdjustmentsByProductId(widget.product.id!);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Product Info Card
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.product.sku != null)
                        Text(
                          'SKU: ${widget.product.sku}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.product.stock}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.product.unit,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Adjustments List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? Center(
              child: Text('Error: ${state.error}'),
            )
                : state.adjustments.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No adjustments yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : _buildAdjustmentsList(state.adjustments),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsList(List<StockAdjustment> adjustments) {
    int runningBalance = widget.product.stock;
    final adjustmentsWithBalance = <Map<String, dynamic>>[];

    for (var i = adjustments.length - 1; i >= 0; i--) {
      final adj = adjustments[i];
      int change = 0;

      // ✅ FIXED: 'return' → 'returned' + proper indentation
      switch (adj.type) {
        case AdjustmentType.add:
        case AdjustmentType.returned:
          change = adj.quantity;
          break;
        case AdjustmentType.subtract:
        case AdjustmentType.damage:
        case AdjustmentType.expired:
          change = -adj.quantity;
          break;
      }

      runningBalance -= change;
      adjustmentsWithBalance.add({
        'adjustment': adj,
        'balance': runningBalance,
      });
    }

    final reversedList = adjustmentsWithBalance.reversed.toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(stockAdjustmentsNotifierProvider.notifier)
            .loadAdjustmentsByProductId(widget.product.id!);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: reversedList.length,
        itemBuilder: (context, index) {
          final item = reversedList[index];
          final adjustment = item['adjustment'] as StockAdjustment;
          final balance = item['balance'] as int;
          return _buildAdjustmentCard(adjustment, balance);
        },
      ),
    );
  }

  Widget _buildAdjustmentCard(StockAdjustment adjustment, int balance) {
    Color typeColor;
    IconData typeIcon;
    String quantityText;

    // ✅ FIXED: 'return' → 'returned' + proper indentation
    switch (adjustment.type) {
      case AdjustmentType.add:
      case AdjustmentType.returned:
        typeColor = Colors.green;
        typeIcon = Icons.add_circle;
        quantityText = '+${adjustment.quantity}';
        break;
      case AdjustmentType.subtract:
      case AdjustmentType.damage:
      case AdjustmentType.expired:
        typeColor = Colors.red;
        typeIcon = Icons.remove_circle;
        quantityText = '-${adjustment.quantity}';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        adjustment.type.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        quantityText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(
                      DateTime.parse(adjustment.date),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (adjustment.reason != null && adjustment.reason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      adjustment.reason!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Balance: $balance ${widget.product.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}