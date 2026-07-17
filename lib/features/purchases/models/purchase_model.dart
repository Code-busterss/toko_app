// lib/features/purchases/models/purchase_model.dart
import 'dart:convert';

/// Normalized purchase line item, stored in the `purchaseitems` table.
class PurchaseItem {
  int? id;
  int? purchaseId;
  int? productId;
  String? productName;
  int quantity;
  double buyingPrice;
  double total;

  PurchaseItem({
    this.id,
    this.purchaseId,
    this.productId,
    this.productName,
    required this.quantity,
    required this.buyingPrice,
    required this.total,
  });

  Map<String, dynamic> toMap({int? purchaseId}) {
    return {
      'id': id,
      'purchaseId': purchaseId ?? this.purchaseId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'buyingPrice': buyingPrice,
      'total': total,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchaseId'] as int?,
      productId: map['productId'] as int?,
      productName: map['productName'] as String?,
      quantity: (map['quantity'] as num).toInt(),
      buyingPrice: (map['buyingPrice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }

  /// Legacy shape used by the old `products` JSON column on the purchases
  /// table. Kept so older code that still reads that column keeps working.
  Map<String, dynamic> toLegacyJsonMap() => {
        'productId': productId,
        'qty': quantity,
        'buyingPrice': buyingPrice,
      };
}

class Purchase {
  int? id;
  int supplierId;
  String? supplierName;
  DateTime purchaseDate;
  String? invoiceNo;
  double subtotal;
  double transportCharges;
  double otherCharges;
  double totalAmount;
  String? notes;
  List<PurchaseItem> items;
  DateTime? createdAt;

  Purchase({
    this.id,
    required this.supplierId,
    this.supplierName,
    required this.purchaseDate,
    this.invoiceNo,
    this.subtotal = 0.0,
    this.transportCharges = 0.0,
    this.otherCharges = 0.0,
    required this.totalAmount,
    this.notes,
    this.items = const [],
    this.createdAt,
  });

  double get grandTotal => subtotal + transportCharges + otherCharges;

  Map<String, dynamic> toMap() {
    // `products` keeps the legacy JSON shape for back-compat with any older
    // readers; the authoritative line items live in the `purchaseitems` table.
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'invoiceNo': invoiceNo,
      'subtotal': subtotal,
      'transportCharges': transportCharges,
      'otherCharges': otherCharges,
      'totalAmount': totalAmount,
      'notes': notes,
      'products': jsonEncode(items.map((x) => x.toLegacyJsonMap()).toList()),
      'date': purchaseDate.toIso8601String(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int?,
      supplierId: map['supplierId'] as int,
      supplierName: map['supplierName'] as String?,
      purchaseDate: DateTime.parse(
        (map['purchaseDate'] as String?) ?? (map['date'] as String),
      ),
      invoiceNo: map['invoiceNo'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      transportCharges: (map['transportCharges'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (map['otherCharges'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      notes: map['notes'] as String?,
      items: const [],
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }
}
