// lib/features/suppliers/models/supplier_model.dart

class Supplier {
  int? id;
  String name;
  String phone;
  String? address;
  String? email;
  String? companyName;
  double totalPurchases;
  double pendingAmount;
  DateTime? createdAt;

  Supplier({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    this.email,
    this.companyName,
    this.totalPurchases = 0.0,
    this.pendingAmount = 0.0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'companyName': companyName,
      'totalPurchases': totalPurchases,
      'pendingAmount': pendingAmount,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String?,
      email: map['email'] as String?,
      companyName: map['companyName'] as String?,
      totalPurchases: (map['totalPurchases'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (map['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }
}
