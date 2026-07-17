// lib/features/orders/models/order_with_customer.dart
import 'package:toko_app/features/orders/models/order_model.dart';

class OrderWithCustomer {
  final Order order;
  final String customerName;
  final String customerPhone;

  OrderWithCustomer({
    required this.order,
    required this.customerName,
    required this.customerPhone,
  });

  /// Calculate payment status based on paid amount
  PaymentStatus get paymentStatus {
    if (order.paidAmount >= order.totalAmount) {
      return PaymentStatus.paid;
    } else if (order.paidAmount > 0) {
      return PaymentStatus.partial;
    } else {
      return PaymentStatus.unpaid;
    }
  }

  double get remainingAmount => order.totalAmount - order.paidAmount;
}

enum PaymentStatus { paid, partial, unpaid }
