// lib/features/expenses/models/expense_model.dart

class Expense {
  int? id;
  String category;
  double amount;
  DateTime date;
  String? notes;
  DateTime? createdAt;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
    );
  }
}
