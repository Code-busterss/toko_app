import 'package:flutter/material.dart';

class PurchaseDetailScreen extends StatelessWidget {
  const PurchaseDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PurchaseDetailScreen')),
      body: const Center(
        child: Text('PurchaseDetailScreen'),
      ),
    );
  }
}
