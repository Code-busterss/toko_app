import 'package:flutter/material.dart';

class CustomerAddEditScreen extends StatelessWidget {
  const CustomerAddEditScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CustomerAddEditScreen')),
      body: const Center(
        child: Text('CustomerAddEditScreen'),
      ),
    );
  }
}
