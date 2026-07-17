import 'package:flutter/material.dart';

class SupplierDetailScreen extends StatelessWidget {
  const SupplierDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SupplierDetailScreen')),
      body: const Center(
        child: Text('SupplierDetailScreen'),
      ),
    );
  }
}
