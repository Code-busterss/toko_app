// lib/features/notifications/notification_service.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/core/database_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category; // low_stock | payment_due | backup
  final String date; // ISO
  final int? refId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.date,
    this.refId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'date': date,
        'refId': refId,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        category: map['category'] as String,
        date: map['date'] as String,
        refId: map['refId'] as int?,
      );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _lowStockChannel = AndroidNotificationDetails(
    'low_stock_channel',
    'Low Stock Alerts',
    channelDescription: 'Alerts when product stock drops to/below minimum.',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _paymentChannel = AndroidNotificationDetails(
    'payment_due_channel',
    'Payment Due',
    channelDescription: 'Reminders for outstanding customer balances.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  static const _backupChannel = AndroidNotificationDetails(
    'backup_channel',
    'Backup Reminders',
    channelDescription: 'Reminders to back up app data.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> init() async {
    if (_initialized) return;
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    _initialized = true;
  }

  Future<void> _notify({
    required int id,
    required String title,
    required String body,
    required String category,
    AndroidNotificationDetails? channel,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: channel ?? _lowStockChannel,
        iOS: const DarwinNotificationDetails(),
      ),
    );
    await _saveHistory(AppNotification(
      id: '${category}_$id',
      title: title,
      body: body,
      category: category,
      date: DateTime.now().toIso8601String(),
    ));
  }

  Future<void> _saveHistory(AppNotification n) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.keyNotificationHistory) ?? [];
    final list = raw
        .map((s) => AppNotification.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    // de-dupe by id within 24h
    list.removeWhere((e) => e.id == n.id);
    list.insert(0, n);
    if (list.length > 50) list.removeRange(50, list.length);
    await prefs.setStringList(
      AppConstants.keyNotificationHistory,
      list.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  Future<List<AppNotification>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.keyNotificationHistory) ?? [];
    return raw
        .map((s) => AppNotification.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> dismiss(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.keyNotificationHistory) ?? [];
    final list = raw
        .map((s) => AppNotification.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .where((e) => e.id != id)
        .map((e) => jsonEncode(e.toMap()))
        .toList();
    await prefs.setStringList(AppConstants.keyNotificationHistory, list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyNotificationHistory);
  }

  /// Runs all checks once. Call on app start.
  Future<void> runAllChecks() async {
    await checkLowStock();
    await checkPaymentDue();
    await checkBackupReminder();
  }

  Future<void> checkLowStock() async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.rawQuery(
        'SELECT id, name, stock, minStock FROM products '
        'WHERE stock <= minStock ORDER BY stock ASC LIMIT 20',
      );
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final name = r['name'] as String;
        final stock = (r['stock'] as num?)?.toInt() ?? 0;
        final min = (r['minStock'] as num?)?.toInt() ?? 0;
        await _notify(
          id: 1000 + i,
          title: 'Low Stock Alert',
          body: '$name is at $stock units (min: $min). Restock soon.',
          category: 'low_stock',
          channel: _lowStockChannel,
        );
      }
    } catch (_) {
      // best-effort
    }
  }

  Future<void> checkPaymentDue() async {
    try {
      final db = await DatabaseService.instance.database;
      final cutoff =
          DateTime.now().subtract(Duration(days: AppConstants.paymentDueDays));
      final rows = await db.rawQuery(
        "SELECT c.id, c.shopName, MAX(o.date) AS lastOrder, "
        "COALESCE(SUM(o.totalAmount - o.paidAmount), 0) AS outstanding "
        "FROM customers c "
        "INNER JOIN orders o ON o.customerId = c.id "
        "WHERE o.status != ? "
        "GROUP BY c.id "
        "HAVING outstanding > 0 AND lastOrder < ? "
        "ORDER BY lastOrder ASC LIMIT 20",
        [3, cutoff.toIso8601String()], // status 3 = completed (cancelled=4)
      );
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final name = r['shopName'] as String;
        final outstanding = (r['outstanding'] as num?)?.toDouble() ?? 0;
        await _notify(
          id: 2000 + i,
          title: 'Payment Due',
          body:
              '$name has an outstanding balance. Follow up for payment.',
          category: 'payment_due',
          channel: _paymentChannel,
        );
      }
    } catch (_) {
      // best-effort
    }
  }

  Future<void> checkBackupReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(AppConstants.keyLastBackupDate);
      final remind = last == null ||
          DateTime.now()
              .difference(DateTime.parse(last))
              .inDays >= AppConstants.backupReminderDays;
      if (remind) {
        await _notify(
          id: 3000,
          title: 'Backup Reminder',
          body: 'It has been a while since your last backup. Back up now.',
          category: 'backup',
          channel: _backupChannel,
        );
      }
    } catch (_) {
      // best-effort
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
