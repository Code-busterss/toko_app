// lib/features/payments/models/payment_model.dart
import 'package:toko_app/shared/models/app_enums.dart';

class Payment {
  int? id;
  int? orderId;
  int customerId;
  String? customerName;
  double amount;
  DateTime date;
  String? notes;
  PaymentType type;
  DateTime? createdAt;

  Payment({
    this.id,
    this.orderId,
    required this.customerId,
    this.customerName,
    required this.amount,
    required this.date,
    this.notes,
    required this.type,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'type': type.index,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    }..removeWhere((key, v) => v == null && key == 'id');
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      orderId: map['orderId'] as int?,
      customerId: map['customerId'] as int,
      customerName: map['customerName'] as String?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      type: PaymentType.values[map['type'] as int],
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }
}
