import 'package:flutter/material.dart';

class OrderAddEditScreen extends StatelessWidget {
  const OrderAddEditScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OrderAddEditScreen')),
      body: const Center(
        child: Text('OrderAddEditScreen'),
      ),
    );
  }
}
