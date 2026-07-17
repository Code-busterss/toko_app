// lib/features/stock/screens/stock_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/features/stock/screens/stock_adjustment_screen.dart';
import 'package:toko_app/features/stock/screens/stock_history_screen.dart'; // ✅ ADDED: Missing import

import '../providers/stock_notifier.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockState = ref.watch(stockNotifierProvider);
    final stockNotifier = ref.read(stockNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => stockNotifier.loadStock(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          _buildStatsCards(stockNotifier),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: stockNotifier.setSearchQuery,
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildFilterChip('All', StockFilter.all, stockState.filter, stockNotifier),
                _buildFilterChip('In Stock', StockFilter.inStock, stockState.filter, stockNotifier),
                _buildFilterChip('Low Stock', StockFilter.lowStock, stockState.filter, stockNotifier),
                _buildFilterChip('Out of Stock', StockFilter.outOfStock, stockState.filter, stockNotifier),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Product List
          Expanded(
            child: stockState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stockState.error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${stockState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => stockNotifier.loadStock(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _buildProductList(context, ref, stockNotifier.filteredProducts), // ✅ FIXED: Pass ref
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StockAdjustmentScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Adjust Stock'),
      ),
    );
  }

  Widget _buildStatsCards(StockNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildStatCard('Total', notifier.totalProducts.toString(), Colors.blue),
          const SizedBox(width: 8),
          _buildStatCard('In Stock', notifier.inStockCount.toString(), Colors.green),
          const SizedBox(width: 8),
          _buildStatCard('Low', notifier.lowStockCount.toString(), Colors.orange),
          const SizedBox(width: 8),
          _buildStatCard('Out', notifier.outOfStockCount.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), // ✅ FIXED: withOpacity → withValues
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)), // ✅ FIXED
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      StockFilter filter,
      StockFilter currentFilter,
      StockNotifier notifier,
      ) {
    final isSelected = currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) notifier.setFilter(filter);
        },
        selectedColor: Colors.blue.withValues(alpha: 0.2), // ✅ FIXED
        checkmarkColor: Colors.blue,
      ),
    );
  }

  // ✅ FIXED: Added WidgetRef parameter
  Widget _buildProductList(BuildContext context, WidgetRef ref, List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(stockNotifierProvider.notifier).loadStock(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Determine stock status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (product.stock == 0) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
      statusIcon = Icons.error;
    } else if (product.stock <= product.minStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'In Stock';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockHistoryScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1), // ✅ FIXED
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 32),
              ),
              const SizedBox(width: 16),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.sku != null)
                      Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Stock: ${product.stock} ${product.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(Min: ${product.minStock})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1), // ✅ FIXED
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}