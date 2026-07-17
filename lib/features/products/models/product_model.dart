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
      name: map['name'] as String,
      category: map['category'] as String?,
      brand: map['brand'] as String?,
      buyingPrice: (map['buyingPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      wholesalePrice: (map['wholesalePrice'] as num).toDouble(),
      stock: map['stock'] as int,
      minStock: map['minStock'] as int,
      unit: map['unit'] as String,
      supplierId: map['supplierId'] as int?,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }
}
