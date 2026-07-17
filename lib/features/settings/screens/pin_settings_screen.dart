// lib/features/settings/screens/pin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/constants/constants.dart';
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
    try {
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setPin() async {
    try {
      final result = await context.push<bool>(AppConstants.routePinLock, extra: {'isSettingPin': true});

      if (result == true) {
        await _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN set successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting PIN: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disablePin() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable PIN'),
          content: const Text('Are you sure you want to disable PIN lock?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(pinServiceProvider).disablePin();
        await _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFingerprint(bool value) async {
    try {
      await ref.read(pinServiceProvider).enableFingerprint(value);
      setState(() {
        _fingerprintEnabled = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling fingerprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
