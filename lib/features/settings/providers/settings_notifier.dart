// lib/features/settings/providers/settings_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toko_app/core/constants/constants.dart';

/// Holds the app-level settings stored in SharedPreferences.
class SettingsState {
  final bool darkMode;
  final ThemeMode themeMode;
  final String currencySymbol;
  final String currencyCode;
  final String companyName;
  final String companyPhone;
  final String companyAddress;
  final String companyLogo; // base64 or ''
  final String invoicePrefix;
  final int invoiceStartNo;
  final String? lastBackupDate;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.darkMode = false,
    this.themeMode = ThemeMode.system,
    this.currencySymbol = AppConstants.currencySymbol,
    this.currencyCode = AppConstants.currencyCode,
    this.companyName = '',
    this.companyPhone = '',
    this.companyAddress = '',
    this.companyLogo = '',
    this.invoicePrefix = 'INV-',
    this.invoiceStartNo = 1,
    this.lastBackupDate,
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    bool? darkMode,
    ThemeMode? themeMode,
    String? currencySymbol,
    String? currencyCode,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
    String? companyLogo,
    String? invoicePrefix,
    int? invoiceStartNo,
    String? lastBackupDate,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      companyAddress: companyAddress ?? this.companyAddress,
      companyLogo: companyLogo ?? this.companyLogo,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceStartNo: invoiceStartNo ?? this.invoiceStartNo,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _prefs;

  @override
  SettingsState build() {
    _init();
    return const SettingsState();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      darkMode: _prefs.getBool(AppConstants.keyDarkMode) ?? false,
      themeMode: _themeModeFromString(
        _prefs.getString(AppConstants.keyThemeMode),
      ),
      currencySymbol:
          _prefs.getString(AppConstants.keyCurrencySymbol) ??
          AppConstants.currencySymbol,
      currencyCode:
          _prefs.getString(AppConstants.keyCurrencyCode) ??
          AppConstants.currencyCode,
      companyName: _prefs.getString(AppConstants.keyCompanyName) ?? '',
      companyPhone: _prefs.getString(AppConstants.keyCompanyPhone) ?? '',
      companyAddress: _prefs.getString(AppConstants.keyCompanyAddress) ?? '',
      companyLogo: _prefs.getString(AppConstants.keyCompanyLogo) ?? '',
      invoicePrefix:
          _prefs.getString(AppConstants.keyInvoicePrefix) ?? 'INV-',
      invoiceStartNo: _prefs.getInt(AppConstants.keyInvoiceStartNo) ?? 1,
      lastBackupDate: _prefs.getString(AppConstants.keyLastBackupDate),
    );
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    await _prefs.setBool(AppConstants.keyDarkMode, enabled);
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setString(AppConstants.keyThemeMode, _themeModeToString(mode));
    state = state.copyWith(darkMode: enabled, themeMode: mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(AppConstants.keyThemeMode, _themeModeToString(mode));
    state = state.copyWith(
      themeMode: mode,
      darkMode: mode == ThemeMode.dark,
    );
  }

  Future<void> setCurrency(String code, String symbol) async {
    await _prefs.setString(AppConstants.keyCurrencyCode, code);
    await _prefs.setString(AppConstants.keyCurrencySymbol, symbol);
    state = state.copyWith(currencyCode: code, currencySymbol: symbol);
  }

  Future<void> saveBusinessInfo({
    required String name,
    required String phone,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _prefs.setString(AppConstants.keyCompanyName, name);
      await _prefs.setString(AppConstants.keyCompanyPhone, phone);
      await _prefs.setString(AppConstants.keyCompanyAddress, address);
      state = state.copyWith(
        isLoading: false,
        companyName: name,
        companyPhone: phone,
        companyAddress: address,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save business info: $e',
      );
    }
  }

  Future<void> saveLogo(String base64) async {
    await _prefs.setString(AppConstants.keyCompanyLogo, base64);
    state = state.copyWith(companyLogo: base64);
  }

  Future<void> clearLogo() async {
    await _prefs.remove(AppConstants.keyCompanyLogo);
    state = state.copyWith(companyLogo: '');
  }

  Future<void> saveInvoiceSettings({
    required String prefix,
    required int startNo,
  }) async {
    await _prefs.setString(AppConstants.keyInvoicePrefix, prefix);
    await _prefs.setInt(AppConstants.keyInvoiceStartNo, startNo);
    state = state.copyWith(invoicePrefix: prefix, invoiceStartNo: startNo);
  }

  Future<void> setLastBackupDate(String iso) async {
    await _prefs.setString(AppConstants.keyLastBackupDate, iso);
    state = state.copyWith(lastBackupDate: iso);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

/// Convenience: current theme mode for MaterialApp.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsNotifierProvider).themeMode;
});
