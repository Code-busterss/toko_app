// lib/features/orders/providers/order_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/orders/models/order_model.dart';
import 'package:toko_app/features/orders/repositories/order_repository.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/products/models/product_model.dart';
import 'package:toko_app/shared/models/app_enums.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.sellingPrice * quantity;
}

class OrderDraft {
  final Customer? customer;
  final List<CartItem> items;
  final double discount;
  final double tax;
  final PaymentMethod paymentMethod;
  final double paidAmount;
  final String notes;

  OrderDraft({
    this.customer,
    List<CartItem>? items,
    this.discount = 0.0,
    this.tax = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.paidAmount = 0.0,
    this.notes = '',
  }) : items = items ?? [];

  double get subtotal {
    double total = 0;
    for (final item in items) {
      total += item.subtotal;
    }
    return total;
  }

  double get discountAmount => subtotal * (discount / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (tax / 100);
  double get grandTotal => taxableAmount + taxAmount;
  double get remainingAmount => grandTotal - paidAmount;

  OrderDraft copyWith({
    Customer? customer,
    List<CartItem>? items,
    double? discount,
    double? tax,
    PaymentMethod? paymentMethod,
    double? paidAmount,
    String? notes,
  }) {
    return OrderDraft(
      customer: customer ?? this.customer,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
    );
  }
}

class OrderNotifier extends Notifier<OrderDraft> {
  final OrderRepository _repository = OrderRepository();

  OrderRepository get repository => _repository;

  @override
  OrderDraft build() {
    return OrderDraft();
  }

  void reset() {
    state = OrderDraft();
  }

  void setCustomer(Customer customer) {
    state = state.copyWith(customer: customer);
  }

  void addItem(Product product) {
    final newItems = List<CartItem>.from(state.items);
    final existingIndex = newItems.indexWhere(
          (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final existing = newItems[existingIndex];
      if (existing.quantity < product.stock) {
        newItems[existingIndex] = CartItem(
          product: product,
          quantity: existing.quantity + 1,
        );
      }
    } else {
      if (product.stock > 0) {
        newItems.add(CartItem(product: product, quantity: 1));
      }
    }

    state = state.copyWith(items: newItems);
  }

  void updateItemQuantity(int productId, int quantity) {
    final newItems = List<CartItem>.from(state.items);
    final index = newItems.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final product = newItems[index].product;
      final clampedQty = quantity.clamp(0, product.stock);

      if (clampedQty == 0) {
        newItems.removeAt(index);
      } else {
        newItems[index] = CartItem(
          product: product,
          quantity: clampedQty,
        );
      }
    }

    state = state.copyWith(items: newItems);
  }

  void removeItem(int productId) {
    final newItems = state.items
        .where((item) => item.product.id != productId)
        .toList();
    state = state.copyWith(items: newItems);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount.clamp(0.0, 100.0));
  }

  void setTax(double tax) {
    state = state.copyWith(tax: tax.clamp(0.0, 100.0));
  }

  void setPaymentMethod(PaymentMethod method) {
    double newPaidAmount = state.paidAmount;

    if (method == PaymentMethod.cash) {
      newPaidAmount = state.grandTotal;
    } else if (method == PaymentMethod.credit) {
      newPaidAmount = 0.0;
    }

    state = state.copyWith(
      paymentMethod: method,
      paidAmount: newPaidAmount,
    );
  }

  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount.clamp(0.0, state.grandTotal));
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<String> saveOrder() async {
    if (state.customer == null) {
      throw Exception('Customer is required');
    }
    if (state.items.isEmpty) {
      throw Exception('At least one item is required');
    }

    final invoiceNumber = await _repository.generateInvoiceNumber();

    final orderItems = state.items.map((cartItem) {
      return OrderItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        qty: cartItem.quantity,
        rate: cartItem.product.sellingPrice,
        total: cartItem.subtotal,
      );
    }).toList();

    final order = Order(
      customerId: state.customer!.id!,
      items: orderItems,
      discount: state.discountAmount,
      tax: state.taxAmount,
      totalAmount: state.grandTotal,
      paidAmount: state.paidAmount,
      paymentMethod: state.paymentMethod,
      status: OrderStatus.confirmed,
      notes: state.notes.isEmpty ? null : state.notes,
      invoiceNumber: invoiceNumber,
      date: DateTime.now(),
    );

    await _repository.createOrder(order, deductStock: true);

    final remaining = state.remainingAmount;
    if (remaining > 0) {
      await _repository.updateCustomerBalance(
        state.customer!.id!,
        remaining,
      );
    }

    reset();
    return invoiceNumber;
  }
}

final orderNotifierProvider = NotifierProvider<OrderNotifier, OrderDraft>(
  OrderNotifier.new,
);