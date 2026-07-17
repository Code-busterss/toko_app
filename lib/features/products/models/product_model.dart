// lib/features/products/models/product_model.dart

class Product {
  int? id;
  String? sku;
  String? barcode;
  String name;
  String? category;
  String? brand;
  double buyingPrice;
  double sellingPrice;
  double wholesalePrice;
  int stock;
  int minStock;
  String unit;
  int? supplierId;
  double tax;
  double discount;
  DateTime? createdAt;

  Product({
    this.id,
    this.sku,
    this.barcode,
    required this.name,
    this.category,
    this.brand,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.wholesalePrice,
    required this.stock,
    required this.minStock,
    required this.unit,
    this.supplierId,
    this.tax = 0.0,
    this.discount = 0.0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'category': category,
      'brand': brand,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'wholesalePrice': wholesalePrice,
      'stock': stock,
      'minStock': minStock,
      'unit': unit,
      'supplierId': supplierId,
      'tax': tax,
      'discount': discount,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      name: map['name'] as String? ?? '',
      category: map['category'] as String?,
      brand: map['brand'] as String?,
      buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] as int? ?? 0,
      minStock: map['minStock'] as int? ?? 0,
      unit: map['unit'] as String? ?? 'pcs',
      supplierId: map['supplierId'] as int?,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }

  Product copyWith({
    int? id,
    String? sku,
    String? barcode,
    String? name,
    String? category,
    String? brand,
    double? buyingPrice,
    double? sellingPrice,
    double? wholesalePrice,
    int? stock,
    int? minStock,
    String? unit,
    int? supplierId,
    double? tax,
    double? discount,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      supplierId: supplierId ?? this.supplierId,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
