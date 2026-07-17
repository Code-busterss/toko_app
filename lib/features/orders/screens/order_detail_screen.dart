import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OrderDetailScreen')),
      body: const Center(
        child: Text('OrderDetailScreen'),
      ),
    );
  }
}
