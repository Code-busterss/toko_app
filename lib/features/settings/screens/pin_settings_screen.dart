// lib/features/settings/screens/pin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/features/auth/providers/pin_provider.dart';
import 'package:toko_app/features/auth/screens/pin_lock_screen.dart';
import 'package:toko_app/features/auth/services/fingerprint_service.dart';

class PinSettingsScreen extends ConsumerStatefulWidget {
  const PinSettingsScreen({super.key});

  @override
  ConsumerState<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends ConsumerState<PinSettingsScreen> {
  final FingerprintService _fingerprintService = FingerprintService();
  bool _biometricAvailable = false;
  bool _pinEnabled = false;
  bool _fingerprintEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometricAvailable = await _fingerprintService.isBiometricAvailable();
    final pinEnabled = await ref.read(pinServiceProvider).isPinSet();
    final fingerprintEnabled = await ref.read(pinServiceProvider).isFingerprintEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = biometricAvailable;
        _pinEnabled = pinEnabled;
        _fingerprintEnabled = fingerprintEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _setPin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PinLockScreen(isSettingPin: true),
      ),
    );

    if (result == true) {
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN set successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _disablePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PIN'),
        content: const Text('Are you sure you want to disable PIN lock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(pinServiceProvider).disablePin();
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _toggleFingerprint(bool value) async {
    await ref.read(pinServiceProvider).enableFingerprint(value);
    setState(() {
      _fingerprintEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('PIN Lock'),
            subtitle: Text(_pinEnabled ? 'PIN is enabled' : 'PIN is disabled'),
            value: _pinEnabled,
            onChanged: (value) {
              if (value) {
                _setPin();
              } else {
                _disablePin();
              }
            },
            secondary: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (_pinEnabled && _biometricAvailable) ...[
            const Divider(),
            SwitchListTile(
              title: const Text('Fingerprint / Face ID'),
              subtitle: const Text('Use biometric authentication'),
              value: _fingerprintEnabled,
              onChanged: _toggleFingerprint,
              secondary: Icon(
                Icons.fingerprint,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          if (!_biometricAvailable) ...[
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              title: const Text('Biometric not available'),
              subtitle: const Text('Your device does not support biometric authentication'),
            ),
          ],
        ],
      ),
    );
  }
}
