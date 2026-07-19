// lib/features/auth/screens/pin_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/features/auth/providers/pin_provider.dart';
import 'package:toko_app/features/auth/services/fingerprint_service.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  final bool isSettingPin;
  final Function(String)? onPinSet;
  final VoidCallback? onAuthenticated;

  const PinLockScreen({
    super.key,
    this.isSettingPin = false,
    this.onPinSet,
    this.onAuthenticated,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class PinLockUiState {
  final String pin;
  final String confirmPin;
  final bool isConfirming;
  final bool isLoading;
  final bool biometricAvailable;
  final String? errorMessage;

  const PinLockUiState({
    this.pin = '',
    this.confirmPin = '',
    this.isConfirming = false,
    this.isLoading = false,
    this.biometricAvailable = false,
    this.errorMessage,
  });

  PinLockUiState copyWith({
    String? pin,
    String? confirmPin,
    bool? isConfirming,
    bool? isLoading,
    bool? biometricAvailable,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PinLockUiState(
      pin: pin ?? this.pin,
      confirmPin: confirmPin ?? this.confirmPin,
      isConfirming: isConfirming ?? this.isConfirming,
      isLoading: isLoading ?? this.isLoading,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PinLockUiNotifier extends StateNotifier<PinLockUiState> {
  PinLockUiNotifier() : super(const PinLockUiState());

  void setBiometricAvailable(bool v) =>
      state = state.copyWith(biometricAvailable: v);
  void setLoading(bool v) => state = state.copyWith(isLoading: v);
  void setError(String? e) => state = state.copyWith(errorMessage: e);

  void onKeyTap(String key, int maxLen) {
    if (state.pin.length < maxLen) {
      state = state.copyWith(pin: state.pin + key, clearError: true);
    }
  }

  void onBackspace() {
    if (state.pin.isNotEmpty) {
      state = state.copyWith(
        pin: state.pin.substring(0, state.pin.length - 1),
        clearError: true,
      );
    }
  }

  void clear() => state = state.copyWith(pin: '', clearError: true);

  void beginConfirm() {
    state = PinLockUiState(
      isConfirming: true,
      confirmPin: state.pin,
      biometricAvailable: state.biometricAvailable,
    );
  }

  void resetToEntry() {
    state = PinLockUiState(
      biometricAvailable: state.biometricAvailable,
    );
  }
}

final pinLockUiProvider =
    StateNotifierProvider<PinLockUiNotifier, PinLockUiState>((ref) {
  return PinLockUiNotifier();
});

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final FingerprintService _fingerprintService = FingerprintService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _fingerprintService.isBiometricAvailable();
    if (mounted) {
      ref.read(pinLockUiProvider.notifier).setBiometricAvailable(available);
    }
  }

  Future<void> _handlePinComplete() async {
    final ui = ref.read(pinLockUiProvider);
    final notifier = ref.read(pinLockUiProvider.notifier);

    if (widget.isSettingPin) {
      if (!ui.isConfirming) {
        notifier.beginConfirm();
      } else {
        if (ui.pin == ui.confirmPin) {
          await ref.read(pinServiceProvider).setPin(ui.pin);
          widget.onPinSet?.call(ui.pin);
          if (mounted) Navigator.pop(context, true);
        } else {
          notifier.resetToEntry();
          notifier.setError('PINs do not match. Try again.');
        }
      }
    } else {
      await _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    final ui = ref.read(pinLockUiProvider);
    final notifier = ref.read(pinLockUiProvider.notifier);
    notifier.setLoading(true);

    final isValid = await ref.read(pinServiceProvider).verifyPin(ui.pin);

    notifier.setLoading(false);

    if (!mounted) return;
    if (isValid) {
      widget.onAuthenticated?.call();
      if (mounted) {
        // Use GoRouter to navigate to dashboard instead of pop
        context.go(AppConstants.routeDashboard);
      }
    } else {
      notifier
        ..clear()
        ..setError('Incorrect PIN. Try again.');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final notifier = ref.read(pinLockUiProvider.notifier);
    notifier.setLoading(true);

    final authenticated =
        await _fingerprintService.authenticateWithBiometrics();

    notifier.setLoading(false);

    if (!mounted) return;
    if (authenticated) {
      widget.onAuthenticated?.call();
      if (mounted) {
        // Use GoRouter to navigate to dashboard instead of pop
        context.go(AppConstants.routeDashboard);
      }
    } else {
      notifier.setError('Biometric authentication failed');
    }
  }

  void _onKeyTap(String key) {
    final notifier = ref.read(pinLockUiProvider.notifier);
    notifier.onKeyTap(key, 4);
    // After update, if PIN now complete, handle.
    final newPin = ref.read(pinLockUiProvider).pin;
    if (newPin.length == 4) {
      _handlePinComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(pinLockUiProvider);
    final isSetting = widget.isSettingPin;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    return Scaffold(
      appBar: isSetting
          ? AppBar(
              title: const Text('Set PIN'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? 24 : 48),
                      Icon(
                        Icons.lock_outline,
                        size: isSmallScreen ? 48 : 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      Text(
                        isSetting
                            ? (ui.isConfirming ? 'Confirm PIN' : 'Enter New PIN')
                            : 'Enter PIN',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter 4-digit PIN',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < ui.pin.length
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (ui.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            ui.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (ui.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircularProgressIndicator(),
                        ),
                      _buildNumpad(ui.isLoading, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12 : 24),
                      if (!isSetting && ui.biometricAvailable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: IconButton(
                            onPressed:
                                ui.isLoading ? null : _authenticateWithBiometrics,
                            iconSize: 48,
                            icon: Icon(
                              Icons.fingerprint,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      SizedBox(height: isSmallScreen ? 12 : 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumpad(bool disabled, bool isSmallScreen) {
    final keySize = isSmallScreen ? 64.0 : 80.0;
    final horizontalPadding = isSmallScreen ? 24.0 : 48.0;
    final rowSpacing = isSmallScreen ? 12.0 : 16.0;
    final fontSize = isSmallScreen ? 26.0 : 32.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKey('1', disabled, keySize, fontSize),
              _buildKey('2', disabled, keySize, fontSize),
              _buildKey('3', disabled, keySize, fontSize),
            ],
          ),
          SizedBox(height: rowSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKey('4', disabled, keySize, fontSize),
              _buildKey('5', disabled, keySize, fontSize),
              _buildKey('6', disabled, keySize, fontSize),
            ],
          ),
          SizedBox(height: rowSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKey('7', disabled, keySize, fontSize),
              _buildKey('8', disabled, keySize, fontSize),
              _buildKey('9', disabled, keySize, fontSize),
            ],
          ),
          SizedBox(height: rowSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(width: keySize),
              _buildKey('0', disabled, keySize, fontSize),
              _buildBackspace(disabled, keySize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key, bool disabled, double size, double fontSize) {
    return InkWell(
      onTap: disabled ? null : () => _onKeyTap(key),
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Text(
          key,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: fontSize,
              ),
        ),
      ),
    );
  }

  Widget _buildBackspace(bool disabled, double size) {
    return InkWell(
      onTap: disabled
          ? null
          : () => ref.read(pinLockUiProvider.notifier).onBackspace(),
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace_outlined,
          size: size * 0.4,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
