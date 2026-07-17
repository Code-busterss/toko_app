import 'package:flutter/material.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ExpenseListScreen')),
      body: const Center(
        child: Text('ExpenseListScreen'),
      ),
    );
  }
}
