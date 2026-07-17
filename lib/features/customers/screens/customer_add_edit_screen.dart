// lib/features/customers/screens/customer_add_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:toko_app/features/customers/models/customer_model.dart';
import 'add_customer_screen.dart';

class CustomerAddEditScreen extends StatelessWidget {
  const CustomerAddEditScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    // This is a placeholder that redirects to AddCustomerScreen
    // The actual add/edit functionality is in AddCustomerScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
    });
    
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
