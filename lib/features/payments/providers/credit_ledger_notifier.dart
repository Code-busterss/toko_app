// lib/features/payments/providers/credit_ledger_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/payments/repositories/payment_repository.dart';

class CreditLedgerState {
  final int? customerId;
  final Customer? customer;
  final AsyncValue<List<LedgerEntry>> entries;
  final double currentBalance;
  final double totalDebit;
  final double totalCredit;
  final String? errorMessage;

  const CreditLedgerState({
    this.customerId,
    this.customer,
    this.entries = const AsyncLoading(),
    this.currentBalance = 0.0,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.errorMessage,
  });

  CreditLedgerState copyWith({
    int? customerId,
    Customer? customer,
    AsyncValue<List<LedgerEntry>>? entries,
    double? currentBalance,
    double? totalDebit,
    double? totalCredit,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreditLedgerState(
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      entries: entries ?? this.entries,
      currentBalance: currentBalance ?? this.currentBalance,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CreditLedgerNotifier extends Notifier<CreditLedgerState> {
  final PaymentRepository _repository = PaymentRepository();

  @override
  CreditLedgerState build() {
    return const CreditLedgerState();
  }

  Future<void> loadCustomer(int customerId) async {
    state = state.copyWith(
      customerId: customerId,
      entries: const AsyncLoading(),
      clearError: true,
    );

    try {
      final customer = await _repository.getCustomerById(customerId);
      if (customer == null) {
        state = state.copyWith(errorMessage: 'Customer not found');
        return;
      }

      final entries = await _repository.getCustomerLedger(customerId);

      double totalDebit = 0;
      double totalCredit = 0;
      for (final entry in entries) {
        totalDebit += entry.debit;
        totalCredit += entry.credit;
      }

      final currentBalance =
          entries.isNotEmpty ? entries.last.runningBalance : 0.0;

      state = state.copyWith(
        customer: customer,
        entries: AsyncData(entries),
        currentBalance: currentBalance,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
    } catch (e, stackTrace) {
      state = state.copyWith(
        entries: AsyncError(e, stackTrace),
        errorMessage: 'Failed to load ledger: $e',
      );
    }
  }

  Future<void> refresh() async {
    if (state.customerId != null) {
      await loadCustomer(state.customerId!);
    }
  }
}

final creditLedgerNotifierProvider =
    NotifierProvider<CreditLedgerNotifier, CreditLedgerState>(
  CreditLedgerNotifier.new,
);
