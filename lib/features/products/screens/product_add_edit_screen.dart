import 'package:flutter/material.dart';

class ProductAddEditScreen extends StatelessWidget {
  const ProductAddEditScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ProductAddEditScreen')),
      body: const Center(
        child: Text('ProductAddEditScreen'),
      ),
    );
  }
}
