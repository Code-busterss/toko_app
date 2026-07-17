// lib/features/stock/models/stock_adjustment_model.dart

// ✅ Import the shared one
import 'package:toko_app/shared/models/app_enums.dart';

class StockAdjustment {
  final int? id;
  final int productId;
  final AdjustmentType type;
  final int quantity;
  final String? reason;
  final String date; // ✅ Changed to String to match database

  StockAdjustment({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.reason,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'type': type.index,
      'quantity': quantity,
      'reason': reason,
      'date': date, // Already a String
    };
  }

  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      type: AdjustmentType.values[map['type'] as int],
      quantity: map['quantity'] as int,
      reason: map['reason'] as String?,
      date: map['date'] as String,
    );
  }

  StockAdjustment copyWith({
    int? id,
    int? productId,
    AdjustmentType? type,
    int? quantity,
    String? reason,
    String? date,
  }) {
    return StockAdjustment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      date: date ?? this.date,
    );
  }
}