// lib/features/customers/providers/customer_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/customers/repositories/customer_repository.dart';

class CustomerFilter {
  final String searchQuery;

  const CustomerFilter({this.searchQuery = ''});

  CustomerFilter copyWith({String? searchQuery}) {
    return CustomerFilter(searchQuery: searchQuery ?? this.searchQuery);
  }
}

class CustomerNotifier extends Notifier<AsyncValue<List<Customer>>> {
  final CustomerRepository _repository = CustomerRepository();
  CustomerFilter _filter = const CustomerFilter();

  CustomerFilter get filter => _filter;
  CustomerRepository get repository => _repository;

  @override
  AsyncValue<List<Customer>> build() {
    fetchCustomers();
    return const AsyncLoading();
  }

  void setFilter(CustomerFilter newFilter) {
    _filter = newFilter;
    fetchCustomers();
  }

  void clearFilter() {
    _filter = const CustomerFilter();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    state = const AsyncLoading();
    try {
      final allCustomers = await _repository.getAllCustomers();

      List<Customer> filtered = allCustomers;
      if (_filter.searchQuery.isNotEmpty) {
        final query = _filter.searchQuery.toLowerCase();
        filtered = allCustomers.where((c) {
          return c.shopName.toLowerCase().contains(query) ||
              c.ownerName.toLowerCase().contains(query) ||
              c.phone.contains(query) ||
              (c.email?.toLowerCase().contains(query) ?? false) ||
              (c.city?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      state = AsyncData(filtered);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  Future<int> addCustomer(Customer customer) async {
    final id = await _repository.addCustomer(customer);
    await fetchCustomers();
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _repository.updateCustomer(customer);
    await fetchCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _repository.deleteCustomer(id);
    await fetchCustomers();
  }
}

final customerNotifierProvider =
    NotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>(
  CustomerNotifier.new,
);
