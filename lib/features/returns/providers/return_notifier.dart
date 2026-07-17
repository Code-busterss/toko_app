// lib/features/returns/providers/return_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/returns/models/return_model.dart';
import 'package:toko_app/features/returns/repositories/return_repository.dart';

class SelectedReturnItem {
  final OrderItem orderItem;
  int returnQty;

  SelectedReturnItem({required this.orderItem, this.returnQty = 0});

  bool get isSelected => returnQty > 0;
  double get returnTotal => orderItem.rate * returnQty;
}

class ReturnState {
  final AsyncValue<List<Map<String, dynamic>>> orders;
  final Map<String, dynamic>? selectedOrderData;
  final Order? selectedOrder;
  final String? customerName;
  final List<SelectedReturnItem> returnItems;
  final String reason;
  final double totalReturnAmount;
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;
  final int? savedReturnId;
  final double alreadyReturnedAmount;

  const ReturnState({
    this.orders = const AsyncLoading(),
    this.selectedOrderData,
    this.selectedOrder,
    this.customerName,
    this.returnItems = const [],
    this.reason = '',
    this.totalReturnAmount = 0.0,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
    this.savedReturnId,
    this.alreadyReturnedAmount = 0.0,
  });

  ReturnState copyWith({
    AsyncValue<List<Map<String, dynamic>>>? orders,
    Map<String, dynamic>? selectedOrderData,
    Order? selectedOrder,
    String? customerName,
    List<SelectedReturnItem>? returnItems,
    String? reason,
    double? totalReturnAmount,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
    int? savedReturnId,
    double? alreadyReturnedAmount,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearSelection = false,
    bool clearSavedReturn = false,
  }) {
    return ReturnState(
      orders: orders ?? this.orders,
      selectedOrderData: clearSelection ? null : (selectedOrderData ?? this.selectedOrderData),
      selectedOrder: clearSelection ? null : (selectedOrder ?? this.selectedOrder),
      customerName: clearSelection ? null : (customerName ?? this.customerName),
      returnItems: clearSelection ? [] : (returnItems ?? this.returnItems),
      reason: clearSelection ? '' : (reason ?? this.reason),
      totalReturnAmount: clearSelection ? 0.0 : (totalReturnAmount ?? this.totalReturnAmount),
      isSaving: isSaving ?? this.isSaving,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedReturnId: clearSavedReturn ? null : (savedReturnId ?? this.savedReturnId),
      alreadyReturnedAmount: clearSelection ? 0.0 : (alreadyReturnedAmount ?? this.alreadyReturnedAmount),
    );
  }

  bool get hasSelectedItems => returnItems.any((item) => item.isSelected);
  int get selectedItemsCount => returnItems.where((item) => item.isSelected).length;
}

class ReturnNotifier extends Notifier<ReturnState> {
  final ReturnRepository _repository = ReturnRepository();

  @override
  ReturnState build() {
    _loadOrders();
    return const ReturnState();
  }

  Future<void> _loadOrders() async {
    try {
      final results = await _repository.getCompletedOrders().then((orders) async {
        final List<Map<String, dynamic>> orderDataList = [];
        for (final order in orders) {
          final data = await _repository.getOrderWithCustomer(order.id!);
          if (data != null) {
            orderDataList.add(data);
          }
        }
        return orderDataList;
      });
      state = state.copyWith(orders: AsyncData(results));
    } catch (e, stackTrace) {
      state = state.copyWith(orders: AsyncError(e, stackTrace));
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true, clearSavedReturn: true);
  }

  Future<void> selectOrder(Map<String, dynamic> orderData) async {
    final order = Order.fromMap(orderData);
    final customerName = orderData['customerName'] as String? ?? 'Unknown';
    final alreadyReturned = await _repository.getTotalReturnedAmount(order.id!);

    final returnItems = order.items.map((item) {
      return SelectedReturnItem(orderItem: item, returnQty: 0);
    }).toList();

    state = state.copyWith(
      selectedOrderData: orderData,
      selectedOrder: order,
      customerName: customerName,
      returnItems: returnItems,
      reason: '',
      totalReturnAmount: 0.0,
      alreadyReturnedAmount: alreadyReturned,
      clearSavedReturn: true,
      clearSuccess: true,
      clearError: true,
    );
  }

  void updateItemQty(int index, int qty) {
    final items = List<SelectedReturnItem>.from(state.returnItems);
    final maxQty = items[index].orderItem.qty;
    final clampedQty = qty.clamp(0, maxQty);

    items[index] = SelectedReturnItem(
      orderItem: items[index].orderItem,
      returnQty: clampedQty,
    );

    double total = 0;
    for (final item in items) {
      total += item.returnTotal;
    }

    state = state.copyWith(
      returnItems: items,
      totalReturnAmount: total,
    );
  }

  void selectAllItems() {
    final items = state.returnItems.map((item) {
      return SelectedReturnItem(
        orderItem: item.orderItem,
        returnQty: item.orderItem.qty,
      );
    }).toList();

    double total = 0;
    for (final item in items) {
      total += item.returnTotal;
    }

    state = state.copyWith(
      returnItems: items,
      totalReturnAmount: total,
    );
  }

  void clearAllItems() {
    final items = state.returnItems.map((item) {
      return SelectedReturnItem(
        orderItem: item.orderItem,
        returnQty: 0,
      );
    }).toList();

    state = state.copyWith(
      returnItems: items,
      totalReturnAmount: 0.0,
    );
  }

  void setReason(String reason) {
    state = state.copyWith(reason: reason);
  }

  Future<int?> submitReturn() async {
    if (state.selectedOrder == null) {
      state = state.copyWith(errorMessage: 'No order selected');
      return null;
    }
    if (!state.hasSelectedItems) {
      state = state.copyWith(errorMessage: 'Select at least one item to return');
      return null;
    }
    if (state.reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a reason for return');
      return null;
    }
    if (state.totalReturnAmount <= 0) {
      state = state.copyWith(errorMessage: 'Return amount must be greater than 0');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final returnItems = state.returnItems
          .where((item) => item.isSelected)
          .map((item) => ReturnItem(
                productId: item.orderItem.productId,
                productName: item.orderItem.productName,
                originalQty: item.orderItem.qty,
                returnQty: item.returnQty,
                rate: item.orderItem.rate,
                total: item.returnTotal,
              ))
          .toList();

      final salesReturn = SalesReturn(
        orderId: state.selectedOrder!.id!,
        invoiceNumber: state.selectedOrder!.invoiceNumber,
        customerId: state.selectedOrder!.customerId,
        customerName: state.customerName ?? 'Unknown',
        items: returnItems,
        totalAmount: state.totalReturnAmount,
        reason: state.reason.trim(),
        status: ReturnStatus.completed,
        createdAt: DateTime.now(),
      );

      // Save return record
      final returnId = await _repository.createReturn(salesReturn);

      // Process: restore stock, adjust balances
      final savedReturn = SalesReturn(
        id: returnId,
        orderId: salesReturn.orderId,
        invoiceNumber: salesReturn.invoiceNumber,
        customerId: salesReturn.customerId,
        customerName: salesReturn.customerName,
        items: salesReturn.items,
        totalAmount: salesReturn.totalAmount,
        reason: salesReturn.reason,
        status: salesReturn.status,
        createdAt: salesReturn.createdAt,
      );

      await _repository.processReturn(savedReturn);

      state = state.copyWith(
        isSaving: false,
        savedReturnId: returnId,
        successMessage: 'Return processed successfully. Stock restored and balance adjusted.',
      );

      return returnId;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to process return: $e',
      );
      return null;
    }
  }
}

final returnNotifierProvider =
    NotifierProvider<ReturnNotifier, ReturnState>(
  ReturnNotifier.new,
);

// Provider for returns by order
final returnsByOrderProvider =
    FutureProvider.family<List<SalesReturn>, int>((ref, orderId) async {
  final repo = ReturnRepository();
  return await repo.getReturnsByOrderId(orderId);
});
