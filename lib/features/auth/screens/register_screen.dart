// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toko_app/core/constants/constants.dart';
import 'package:toko_app/core/theme/theme.dart';
import 'package:toko_app/features/auth/providers/auth_notifier.dart';

class RegisterUiState {
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agreeToTerms;
  const RegisterUiState({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.agreeToTerms = false,
  });
  RegisterUiState copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool? agreeToTerms,
  }) =>
      RegisterUiState(
        obscurePassword: obscurePassword ?? this.obscurePassword,
        obscureConfirmPassword:
            obscureConfirmPassword ?? this.obscureConfirmPassword,
        agreeToTerms: agreeToTerms ?? this.agreeToTerms,
      );
}

class RegisterUiNotifier extends StateNotifier<RegisterUiState> {
  RegisterUiNotifier() : super(const RegisterUiState());
  void togglePassword() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
  void toggleConfirmPassword() => state =
      state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
  void toggleTerms() =>
      state = state.copyWith(agreeToTerms: !state.agreeToTerms);
}

final registerUiProvider =
    StateNotifierProvider<RegisterUiNotifier, RegisterUiState>((ref) {
  return RegisterUiNotifier();
});

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final ui = ref.read(registerUiProvider);
    if (!ui.agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms & Conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref.read(authNotifierProvider.notifier).register(
          companyName: _companyNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to Toko App'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      context.go(AppConstants.routeDashboard);
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
            Text('Registration Error'),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final ui = ref.watch(registerUiProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog(next.errorMessage!);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
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
                    Icons.person_add_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Join Toko App',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to start managing your wholesale business',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _companyNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: AppTheme.inputDecoration(
                    label: 'Company Name',
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your company name';
                    }
                    if (value.length < 2) return 'Company name is too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: AppTheme.inputDecoration(
                    label: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    final digits =
                        value.replaceAll(RegExp(r'[^\d]'), '');
                    if (digits.length < 8) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: ui.obscurePassword,
                  textInputAction: TextInputAction.next,
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
                          .read(registerUiProvider.notifier)
                          .togglePassword,
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: ui.obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: AppTheme.inputDecoration(
                    label: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        ui.obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: ref
                          .read(registerUiProvider.notifier)
                          .toggleConfirmPassword,
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: ui.agreeToTerms,
                        onChanged: (_) => ref
                            .read(registerUiProvider.notifier)
                            .toggleTerms(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ref
                            .read(registerUiProvider.notifier)
                            .toggleTerms(),
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
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
    );
  }
}
