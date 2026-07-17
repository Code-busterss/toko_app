import 'package:flutter/material.dart';

class SupplierAddEditScreen extends StatelessWidget {
  const SupplierAddEditScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SupplierAddEditScreen')),
      body: const Center(
        child: Text('SupplierAddEditScreen'),
      ),
    );
  }
}
