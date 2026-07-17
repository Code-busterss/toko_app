// lib/features/customers/models/customer_model.dart

class Customer {
  int? id;
  String shopName;
  String ownerName;
  String phone;
  String? whatsapp;
  String? address;
  String? city;
  String? email;
  double creditLimit;
  double previousBalance;
  DateTime? createdAt;

  Customer({
    this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    this.whatsapp,
    this.address,
    this.city,
    this.email,
    this.creditLimit = 0.0,
    this.previousBalance = 0.0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopName': shopName,
      'ownerName': ownerName,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'city': city,
      'email': email,
      'creditLimit': creditLimit,
      'previousBalance': previousBalance,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      shopName: map['shopName'] as String,
      ownerName: map['ownerName'] as String,
      phone: map['phone'] as String,
      whatsapp: map['whatsapp'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      email: map['email'] as String?,
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0.0,
      previousBalance: (map['previousBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }
}
