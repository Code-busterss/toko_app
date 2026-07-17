// lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toko_app/core/theme/theme.dart';
import 'package:toko_app/features/auth/providers/auth_notifier.dart';

class ForgotPasswordUiState {
  final bool emailSent;
  const ForgotPasswordUiState({this.emailSent = false});
  ForgotPasswordUiState copyWith({bool? emailSent}) =>
      ForgotPasswordUiState(emailSent: emailSent ?? this.emailSent);
}

class ForgotPasswordUiNotifier
    extends StateNotifier<ForgotPasswordUiState> {
  ForgotPasswordUiNotifier() : super(const ForgotPasswordUiState());
  void markSent() => state = state.copyWith(emailSent: true);
  void reset() => state = state.copyWith(emailSent: false);
}

final forgotPasswordUiProvider =
    StateNotifierProvider<ForgotPasswordUiNotifier, ForgotPasswordUiState>(
        (ref) {
  return ForgotPasswordUiNotifier();
});

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authNotifierProvider.notifier)
        .forgotPassword(_emailController.text.trim());

    if (!mounted) return;
    if (success) {
      ref.read(forgotPasswordUiProvider.notifier).markSent();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authNotifierProvider.notifier).clearError();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final ui = ref.watch(forgotPasswordUiProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog(next.errorMessage!);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
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
                    ui.emailSent ? Icons.mark_email_read : Icons.lock_reset,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  ui.emailSent ? 'Check Your Email' : 'Reset Password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  ui.emailSent
                      ? 'We\'ve sent a password reset link to:\n${_emailController.text}'
                      : 'Enter your email address and we\'ll send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                ),
                if (ui.emailSent) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Email Sent Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Check your email inbox\n'
                          '2. Click the reset link\n'
                          '3. Create a new password\n'
                          '4. Login with new password',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Note: Check spam folder if you don\'t see the email.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSendResetEmail(),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          authState.isLoading ? null : _handleSendResetEmail,
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
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (ui.emailSent) ...[
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(forgotPasswordUiProvider.notifier).reset(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Send to Different Email'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
