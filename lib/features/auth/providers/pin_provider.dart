// lib/features/auth/providers/pin_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toko_app/core/constants/constants.dart';

class PinService {
  static const String _pinKey = AppConstants.keyPinCode;
  static const String _pinEnabledKey = AppConstants.keyPinEnabled;
  static const String _fingerprintEnabledKey = AppConstants.keyFingerprintEnabled;

  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  Future<bool> isFingerprintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fingerprintEnabledKey) ?? false;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);
    return savedPin == pin;
  }

  Future<void> enableFingerprint(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintEnabledKey, enabled);
  }

  Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
    await prefs.setBool(_fingerprintEnabledKey, false);
  }
}

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService();
});

final isPinSetProvider = FutureProvider<bool>((ref) async {
  final pinService = ref.watch(pinServiceProvider);
  return await pinService.isPinSet();
});

final isFingerprintEnabledProvider = FutureProvider<bool>((ref) async {
  final pinService = ref.watch(pinServiceProvider);
  return await pinService.isFingerprintEnabled();
});
