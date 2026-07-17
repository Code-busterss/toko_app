// lib/core/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:toko_app/core/database_service.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseService.instance.database;
});
