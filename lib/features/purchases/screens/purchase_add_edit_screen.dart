import 'package:flutter/material.dart';

class PurchaseAddEditScreen extends StatelessWidget {
  const PurchaseAddEditScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PurchaseAddEditScreen')),
      body: const Center(
        child: Text('PurchaseAddEditScreen'),
      ),
    );
  }
}
