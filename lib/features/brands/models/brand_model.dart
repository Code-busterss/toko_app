// lib/features/brands/models/brand_model.dart
class Brand {
  int? id;
  String name;
  DateTime createdAt;

  Brand({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Brand.fromMap(Map<String, dynamic> map) {
    return Brand(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
