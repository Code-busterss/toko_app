import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReportDetailScreen')),
      body: const Center(
        child: Text('ReportDetailScreen'),
      ),
    );
  }
}
