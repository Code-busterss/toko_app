// lib/shared/models/app_enums.dart

// ============================================
// ORDER STATUS
// ============================================
enum OrderStatus { pending, confirmed, processing, completed, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get color {
    switch (this) {
      case OrderStatus.pending:
        return 'orange';
      case OrderStatus.confirmed:
        return 'blue';
      case OrderStatus.processing:
        return 'purple';
      case OrderStatus.completed:
        return 'green';
      case OrderStatus.cancelled:
        return 'red';
    }
  }
}

// ============================================
// PAYMENT METHOD
// ============================================
enum PaymentMethod { cash, bankTransfer, qris, credit, eWallet }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return 'money';
      case PaymentMethod.bankTransfer:
        return 'account_balance';
      case PaymentMethod.qris:
        return 'qr_code_2';
      case PaymentMethod.credit:
        return 'credit_score';
      case PaymentMethod.eWallet:
        return 'account_balance_wallet';
    }
  }
}

// ============================================
// PAYMENT TYPE
// ============================================
enum PaymentType { incoming, outgoing, refund }

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.incoming:
        return 'Incoming Payment';
      case PaymentType.outgoing:
        return 'Outgoing Payment';
      case PaymentType.refund:
        return 'Refund';
    }
  }
}

// ============================================
// STOCK ADJUSTMENT TYPE
// ============================================
// ✅ FIXED: 'return' → 'returned' (return is a reserved keyword in Dart)
enum AdjustmentType { add, subtract, damage, expired, returned }

extension AdjustmentTypeExtension on AdjustmentType {
  String get displayName {
    switch (this) {
      case AdjustmentType.add:
        return 'Add Stock';
      case AdjustmentType.subtract:
        return 'Subtract Stock';
      case AdjustmentType.damage:
        return 'Damaged';
      case AdjustmentType.expired:
        return 'Expired';
      case AdjustmentType.returned:
        return 'Sales Return';
    }
  }

  String get icon {
    switch (this) {
      case AdjustmentType.add:
        return 'add_circle';
      case AdjustmentType.subtract:
        return 'remove_circle';
      case AdjustmentType.damage:
        return 'broken_image';
      case AdjustmentType.expired:
        return 'timer_off';
      case AdjustmentType.returned:
        return 'assignment_return';
    }
  }

  bool get increasesStock {
    return this == AdjustmentType.add || this == AdjustmentType.returned;
  }

  bool get decreasesStock {
    return this == AdjustmentType.subtract ||
        this == AdjustmentType.damage ||
        this == AdjustmentType.expired;
  }
}