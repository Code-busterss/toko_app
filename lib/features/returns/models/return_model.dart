// lib/features/returns/models/return_model.dart
import 'dart:convert';

enum ReturnStatus { pending, approved, completed, rejected }

class ReturnItem {
  int? productId;
  String productName;
  int originalQty;
  int returnQty;
  double rate;
  double total;

  ReturnItem({
    this.productId,
    required this.productName,
    required this.originalQty,
    required this.returnQty,
    required this.rate,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'originalQty': originalQty,
      'returnQty': returnQty,
      'rate': rate,
      'total': total,
    };
  }

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      productId: map['productId'] as int?,
      productName: map['productName'] as String,
      originalQty: map['originalQty'] as int,
      returnQty: map['returnQty'] as int,
      rate: (map['rate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

class SalesReturn {
  int? id;
  int orderId;
  String invoiceNumber;
  int customerId;
  String customerName;
  List<ReturnItem> items;
  double totalAmount;
  String reason;
  ReturnStatus status;
  bool refundIssued;
  bool stockRestored;
  DateTime createdAt;
  DateTime? completedAt;

  SalesReturn({
    this.id,
    required this.orderId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.reason,
    this.status = ReturnStatus.pending,
    this.refundIssued = false,
    this.stockRestored = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'items': jsonEncode(items.map((x) => x.toMap()).toList()),
      'totalAmount': totalAmount,
      'reason': reason,
      'status': status.index,
      'refundIssued': refundIssued ? 1 : 0,
      'stockRestored': stockRestored ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory SalesReturn.fromMap(Map<String, dynamic> map) {
    return SalesReturn(
      id: map['id'] as int?,
      orderId: map['orderId'] as int,
      invoiceNumber: map['invoiceNumber'] as String,
      customerId: map['customerId'] as int,
      customerName: map['customerName'] as String,
      items: map['items'] != null
          ? (jsonDecode(map['items']) as List)
              .map((x) => ReturnItem.fromMap(x as Map<String, dynamic>))
              .toList()
          : [],
      totalAmount: (map['totalAmount'] as num).toDouble(),
      reason: map['reason'] as String,
      status: ReturnStatus.values[map['status'] as int? ?? 0],
      refundIssued: (map['refundIssued'] as int?) == 1,
      stockRestored: (map['stockRestored'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }
}
