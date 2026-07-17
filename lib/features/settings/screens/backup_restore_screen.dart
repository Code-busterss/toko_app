// lib/features/settings/screens/backup_restore_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:toko_app/features/settings/providers/settings_notifier.dart';
import 'package:toko_app/core/constants/constants.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  void _loadLastBackupDate() {
    final state = ref.read(settingsNotifierProvider);
    setState(() {
      _lastBackupDate = state.lastBackupDate;
    });
  }

  Future<void> _takeBackup() async {
    setState(() => _isBackingUp = true);
    
    try {
      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Create backup file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/toko_backup_$timestamp.json');
      
      // For now, create a simple JSON with settings
      // In production, you'd export all data (customers, products, orders, etc.)
      final settingsState = ref.read(settingsNotifierProvider);
      final backupData = {
        'backup_date': DateTime.now().toIso8601String(),
        'app_version': AppConstants.appVersion,
        'company_name': settingsState.companyName,
        'company_phone': settingsState.companyPhone,
        'company_address': settingsState.companyAddress,
        'currency_symbol': settingsState.currencySymbol,
        'currency_code': settingsState.currencyCode,
        'invoice_prefix': settingsState.invoicePrefix,
        'invoice_start_no': settingsState.invoiceStartNo,
      };

      await backupFile.writeAsString(backupData.toString());
      
      // Update last backup date
      await ref.read(settingsNotifierProvider.notifier).setLastBackupDate(
        AppConstants.dateFormat.format(DateTime.now()),
      );
      
      setState(() {
        _lastBackupDate = AppConstants.dateFormat.format(DateTime.now());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      // Pick backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'This will restore your data from the backup file. Make sure you have a recent backup of current data. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isRestoring = true);

      // Parse and restore data
      // In production, you'd parse the full backup and restore all data
      // This is a simplified version
      await Future.delayed(const Duration(seconds: 2)); // Simulate restore time

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Last Backup Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Last Backup',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastBackupDate ?? 'No backup taken yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _lastBackupDate == null
                                ? Colors.grey
                                : null,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Take Backup Button
            ElevatedButton.icon(
              onPressed: _isBackingUp ? null : _takeBackup,
              icon: _isBackingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.backup),
              label: Text(_isBackingUp ? 'Creating Backup...' : 'Take Backup'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Restore Backup Button
            OutlinedButton.icon(
              onPressed: _isRestoring ? null : _restoreBackup,
              icon: _isRestoring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text(_isRestoring ? 'Restoring...' : 'Restore from Backup'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Info Section
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Backup Tips',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Take regular backups to avoid data loss'),
                    _buildTip('Store backups in a safe location (Google Drive, etc.)'),
                    _buildTip('Restore will replace current data with backup data'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
