// lib/features/customers/screens/add_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'package:toko_app/features/customers/providers/customer_notifier.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final Customer? existingCustomer;

  const AddCustomerScreen({super.key, this.existingCustomer});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _previousBalanceController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      _populateForm(widget.existingCustomer!);
    }
  }

  void _populateForm(Customer customer) {
    _shopNameController.text = customer.shopName;
    _ownerNameController.text = customer.ownerName;
    _phoneController.text = customer.phone;
    _whatsappController.text = customer.whatsapp ?? '';
    _addressController.text = customer.address ?? '';
    _cityController.text = customer.city ?? '';
    _emailController.text = customer.email ?? '';
    _creditLimitController.text = customer.creditLimit.toString();
    _previousBalanceController.text = customer.previousBalance.toString();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _creditLimitController.dispose();
    _previousBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = Customer(
        id: widget.existingCustomer?.id,
        shopName: _shopNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        creditLimit:
            double.tryParse(_creditLimitController.text) ?? 0.0,
        previousBalance:
            double.tryParse(_previousBalanceController.text) ?? 0.0,
      );

      if (widget.existingCustomer != null) {
        await ref
            .read(customerNotifierProvider.notifier)
            .updateCustomer(customer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await ref
            .read(customerNotifierProvider.notifier)
            .addCustomer(customer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCustomer != null
            ? 'Edit Customer'
            : 'Add Customer'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveCustomer,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildShopInfoSection(),
            const SizedBox(height: 16),
            _buildContactInfoSection(),
            const SizedBox(height: 16),
            _buildFinancialInfoSection(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCustomer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.existingCustomer != null
                    ? 'Update Customer'
                    : 'Save Customer',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name *',
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Shop name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Owner Name *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Owner name is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.trim().length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                prefixIcon: Icon(Icons.chat),
                hintText: 'Same as phone if empty',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _creditLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Credit Limit',
                prefixIcon: Icon(Icons.account_balance_wallet),
                prefixText: 'Rp ',
                helperText: 'Maximum credit allowed (0 = no limit)',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Invalid amount';
                  }
                  if (double.parse(value) < 0) {
                    return 'Amount cannot be negative';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _previousBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Previous Balance',
                prefixIcon: Icon(Icons.money),
                prefixText: 'Rp ',
                helperText: 'Opening balance (positive = they owe you)',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Invalid amount';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
