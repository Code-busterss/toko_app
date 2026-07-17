// lib/features/orders/models/order_model.dart
import 'dart:convert';
import 'package:toko_app/shared/models/app_enums.dart';

class OrderItem {
  int? productId;
  String productName;
  int qty;
  double rate;
  double total;

  OrderItem({
    this.productId,
    required this.productName,
    required this.qty,
    required this.rate,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'qty': qty,
      'rate': rate,
      'total': total,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as int?,
      productName: map['productName'] as String,
      qty: map['qty'] as int,
      rate: (map['rate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

class Order {
  int? id;
  int customerId;
  List<OrderItem> items;
  double discount;
  double tax;
  double totalAmount;
  double paidAmount;
  PaymentMethod paymentMethod;
  OrderStatus status;
  String? notes;
  String invoiceNumber;
  DateTime date;
  DateTime? createdAt;

  Order({
    this.id,
    required this.customerId,
    this.items = const [],
    this.discount = 0.0,
    this.tax = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.status = OrderStatus.pending,
    this.notes,
    required this.invoiceNumber,
    required this.date,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'items': jsonEncode(items.map((x) => x.toMap()).toList()),
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod.index,
      'status': status.index,
      'notes': notes,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      items: map['items'] != null
          ? (jsonDecode(map['items']) as List).map((x) => OrderItem.fromMap(x)).toList()
          : [],
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values[map['paymentMethod'] as int? ?? 0],
      status: OrderStatus.values[map['status'] as int? ?? 0],
      notes: map['notes'] as String?,
      invoiceNumber: map['invoiceNumber'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }
}
