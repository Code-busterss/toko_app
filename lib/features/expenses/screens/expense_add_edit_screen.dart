import 'package:flutter/material.dart';

class ExpenseAddEditScreen extends StatelessWidget {
  const ExpenseAddEditScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ExpenseAddEditScreen')),
      body: const Center(
        child: Text('ExpenseAddEditScreen'),
      ),
    );
  }
}
