// lib/features/payments/providers/payment_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/payments/models/payment_model.dart';
import 'package:toko_app/features/payments/repositories/payment_repository.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class ReceivePaymentState {
  final int currentStep;
  final Customer? selectedCustomer;
  final double outstandingBalance;
  final List<Order> unpaidOrders;
  final Set<int> selectedOrderIds;
  final double paymentAmount;
  final PaymentMethod paymentMethod;
  final String notes;
  final String? semanticType; // 'full', 'partial', 'advance'
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;
  final int? savedPaymentId;
  final List<Customer> allCustomers;
  final bool isLoadingCustomers;

  const ReceivePaymentState({
    this.currentStep = 0,
    this.selectedCustomer,
    this.outstandingBalance = 0.0,
    this.unpaidOrders = const [],
    this.selectedOrderIds = const {},
    this.paymentAmount = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.notes = '',
    this.semanticType,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
    this.savedPaymentId,
    this.allCustomers = const [],
    this.isLoadingCustomers = false,
  });

  ReceivePaymentState copyWith({
    int? currentStep,
    Customer? selectedCustomer,
    double? outstandingBalance,
    List<Order>? unpaidOrders,
    Set<int>? selectedOrderIds,
    double? paymentAmount,
    PaymentMethod? paymentMethod,
    String? notes,
    String? semanticType,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
    int? savedPaymentId,
    List<Customer>? allCustomers,
    bool? isLoadingCustomers,
    bool clearSuccess = false,
    bool clearError = false,
    bool clearSavedPayment = false,
    bool clearSelectedCustomer = false,
  }) {
    return ReceivePaymentState(
      currentStep: currentStep ?? this.currentStep,
      selectedCustomer: clearSelectedCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      unpaidOrders: unpaidOrders ?? this.unpaidOrders,
      selectedOrderIds: selectedOrderIds ?? this.selectedOrderIds,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      semanticType: semanticType ?? this.semanticType,
      isSaving: isSaving ?? this.isSaving,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedPaymentId:
          clearSavedPayment ? null : (savedPaymentId ?? this.savedPaymentId),
      allCustomers: allCustomers ?? this.allCustomers,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
    );
  }

  double get totalSelectedOrdersAmount {
    double total = 0;
    for (final order in unpaidOrders) {
      if (selectedOrderIds.contains(order.id)) {
        total += order.totalAmount - order.paidAmount;
      }
    }
    return total;
  }

  bool get isFullPayment =>
      paymentAmount >= outstandingBalance && outstandingBalance > 0;
}

class ReceivePaymentNotifier extends Notifier<ReceivePaymentState> {
  final PaymentRepository _repository = PaymentRepository();

  @override
  ReceivePaymentState build() {
    _loadCustomers();
    return const ReceivePaymentState();
  }

  Future<void> _loadCustomers() async {
    state = state.copyWith(isLoadingCustomers: true);
    try {
      final customers = await _repository.getAllCustomers();
      state = state.copyWith(
        allCustomers: customers,
        isLoadingCustomers: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCustomers: false,
        errorMessage: 'Failed to load customers: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> selectCustomer(Customer customer) async {
    state = state.copyWith(
      selectedCustomer: customer,
      selectedOrderIds: {},
      paymentAmount: 0.0,
      notes: '',
      clearSavedPayment: true,
      clearSuccess: true,
      clearError: true,
      currentStep: 1, // Move to step 1 after selecting customer
    );

    try {
      final outstanding =
          await _repository.getCustomerOutstanding(customer.id!);
      final unpaidOrders =
          await _repository.getCustomerUnpaidOrders(customer.id!);

      state = state.copyWith(
        outstandingBalance: outstanding,
        unpaidOrders: unpaidOrders,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load customer data: $e',
      );
    }
  }

  void clearCustomer() {
    state = ReceivePaymentState(allCustomers: state.allCustomers);
  }

  void toggleOrderSelection(int orderId) {
    final newSet = Set<int>.from(state.selectedOrderIds);
    if (newSet.contains(orderId)) {
      newSet.remove(orderId);
    } else {
      newSet.add(orderId);
    }
    state = state.copyWith(selectedOrderIds: newSet);

    // Auto-update payment amount to match selected orders
    state = state.copyWith(
      paymentAmount: state.totalSelectedOrdersAmount,
    );
  }

  void selectAllOrders() {
    final allIds = state.unpaidOrders.map((o) => o.id!).toSet();
    state = state.copyWith(
      selectedOrderIds: allIds,
      paymentAmount: state.outstandingBalance,
    );
  }

  void clearOrderSelection() {
    state = state.copyWith(
      selectedOrderIds: {},
      paymentAmount: 0.0,
    );
  }

  void setPaymentAmount(double amount) {
    state = state.copyWith(paymentAmount: amount);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setSemanticType(String? semanticType) {
    state = state.copyWith(semanticType: semanticType);
  }

  void fillFullAmount() {
    state = state.copyWith(
      paymentAmount: state.outstandingBalance,
      semanticType: 'full',
    );
  }

  Future<int?> savePayment() async {
    if (state.selectedCustomer == null) {
      state = state.copyWith(errorMessage: 'Please select a customer');
      return null;
    }
    if (state.paymentAmount <= 0) {
      state = state.copyWith(errorMessage: 'Payment amount must be greater than 0');
      return null;
    }
    if (state.paymentAmount > state.outstandingBalance) {
      state = state.copyWith(
        errorMessage: 'Payment amount exceeds outstanding balance',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      // Determine semanticType based on payment amount
      String? semanticType = state.semanticType;
      if (semanticType == null) {
        if (state.paymentAmount >= state.outstandingBalance) {
          semanticType = 'full';
        } else {
          semanticType = 'partial';
        }
      }

      final payment = Payment(
        customerId: state.selectedCustomer!.id!,
        customerName: state.selectedCustomer!.shopName,
        amount: state.paymentAmount,
        date: DateTime.now(),
        notes: state.notes.isEmpty ? null : state.notes,
        semanticType: semanticType,
        type: PaymentType.incoming,
      );

      // Use a single atomic transaction for the whole fan-out (payment +
      // balance + FIFO order distribution) so a partial failure cannot
      // corrupt data.
      final selectedOrders = state.unpaidOrders
          .where((o) => state.selectedOrderIds.contains(o.id))
          .toList();

      final paymentId;
      if (selectedOrders.isEmpty) {
        paymentId = await _repository.recordPaymentAtomic(payment);
      } else {
        paymentId = await _repository.recordPaymentDistributedAtomic(
          payment,
          selectedOrders,
        );
      }

      state = state.copyWith(
        isSaving: false,
        savedPaymentId: paymentId,
        successMessage:
            'Payment of ${state.paymentAmount.toStringAsFixed(0)} recorded successfully',
      );

      return paymentId;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save payment: $e',
      );
      return null;
    }
  }

  Future<void> _distributePaymentToOrders() async {
    // Sort selected orders by date (oldest first)
    final selectedOrders = state.unpaidOrders
        .where((o) => state.selectedOrderIds.contains(o.id))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double remainingPayment = state.paymentAmount;

    for (final order in selectedOrders) {
      if (remainingPayment <= 0) break;

      final orderOutstanding = order.totalAmount - order.paidAmount;
      final paymentForThisOrder =
          remainingPayment >= orderOutstanding ? orderOutstanding : remainingPayment;

      final newPaidAmount = order.paidAmount + paymentForThisOrder;
      await _repository.updateOrderPaidAmount(order.id!, newPaidAmount);

      remainingPayment -= paymentForThisOrder;
    }
  }

  void reset() {
    final customers = state.allCustomers;
    state = ReceivePaymentState(allCustomers: customers);
  }
}

final receivePaymentNotifierProvider =
    NotifierProvider<ReceivePaymentNotifier, ReceivePaymentState>(
  ReceivePaymentNotifier.new,
);
