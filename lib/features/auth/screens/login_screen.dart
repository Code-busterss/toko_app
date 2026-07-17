// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/core/theme/theme.dart';
import 'package:toko_app/features/auth/providers/auth_notifier.dart';
import 'package:toko_app/features/auth/providers/pin_provider.dart';
import 'package:toko_app/features/auth/services/fingerprint_service.dart';

/// Local UI state for login (password visibility + dialog loading) — no setState.
class LoginUiState {
  final bool obscurePassword;
  final bool dialogLoading;
  const LoginUiState({this.obscurePassword = true, this.dialogLoading = false});
  LoginUiState copyWith({bool? obscurePassword, bool? dialogLoading}) =>
      LoginUiState(
        obscurePassword: obscurePassword ?? this.obscurePassword,
        dialogLoading: dialogLoading ?? this.dialogLoading,
      );
}

class LoginUiNotifier extends StateNotifier<LoginUiState> {
  LoginUiNotifier() : super(const LoginUiState());
  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
  void setDialogLoading(bool v) => state = state.copyWith(dialogLoading: v);
}

final loginUiProvider =
    StateNotifierProvider<LoginUiNotifier, LoginUiState>((ref) {
  return LoginUiNotifier();
});

final fingerprintServiceProvider = Provider<FingerprintService>((ref) {
  return FingerprintService();
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      _routeAfterAuth();
    }
  }

  /// After successful authentication (login / biometric), apply PIN gate.
  Future<void> _routeAfterAuth() async {
    final pinService = ref.read(pinServiceProvider);
    final isPinSet = await pinService.isPinSet();
    if (!mounted) return;
    if (isPinSet) {
      context.go(AppConstants.routePinLock);
    } else {
      context.go(AppConstants.routeDashboard);
    }
  }

  Future<void> _handleBiometric() async {
    final hasSession = await ref.read(authNotifierProvider.notifier).hasLocalSession();
    if (!mounted) return;
    if (!hasSession) {
      _showInfo(
        'Biometric Login',
        'Please log in with email and password once before enabling biometric login.',
      );
      return;
    }
    final service = ref.read(fingerprintServiceProvider);
    final available = await service.isBiometricAvailable();
    if (!mounted) return;
    if (!available) {
      _showInfo('Biometric Login', 'Biometrics are not available on this device.');
      return;
    }
    final ok = await service.authenticateWithBiometrics();
    if (!mounted) return;
    if (ok) {
      _routeAfterAuth();
    } else {
      _showInfo('Biometric Login', 'Biometric authentication failed.');
    }
  }

  void _showInfo(String title, String body) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Login Error'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              ref.read(authNotifierProvider.notifier).clearError();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a password reset link.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: AppTheme.inputDecoration(
                  label: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(c);
              final success = await ref
                  .read(authNotifierProvider.notifier)
                  .forgotPassword(emailController.text.trim());
              emailController.dispose();
              if (!mounted) return;
              if (success) {
                _showInfo(
                  'Reset Email Sent',
                  'Check your inbox for password reset instructions.',
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final ui = ref.watch(loginUiProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog(next.errorMessage!);
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue to Toko App',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: AppTheme.inputDecoration(
                      label: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: ui.obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: AppTheme.inputDecoration(
                      label: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          ui.obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: ref
                            .read(loginUiProvider.notifier)
                            .toggleObscure,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : _showForgotPasswordDialog,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              authState.isLoading ? null : _handleBiometric,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Biometric'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.push(AppConstants.routePinLock),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.pin_outlined),
                          label: const Text('PIN'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () =>
                                context.push(AppConstants.routeRegister),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
