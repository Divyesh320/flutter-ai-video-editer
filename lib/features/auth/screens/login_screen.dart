import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

/// Simple logger for login screen
void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  final logMessage = '[$timestamp] [LoginScreen] $message';
  if (kDebugMode) {
    developer.log(logMessage, name: 'LoginScreen');
    // ignore: avoid_print
    print(logMessage);
  }
}

/// Login screen for email authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _log('🚀 LoginScreen initialized');
  }

  @override
  void dispose() {
    _log('🔚 LoginScreen disposed');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen for auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      _log('📊 Auth state changed: ${previous?.status} -> ${next.status}');
      
      if (next.isAuthenticated) {
        _log('✅ Login successful! User: ${next.user?.email}');
        _log('🏠 Navigating to home screen');
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (next.hasError && next.errorMessage != null) {
        _log('❌ Login error: ${next.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (next.isLoading) {
        _log('⏳ Login in progress...');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final result = AuthValidators.validateEmail(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                ),
                const SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 24),
                // Login Button
                FilledButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 32),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                // OAuth Buttons
                OutlinedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () => _handleOAuthLogin(OAuthProvider.google),
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    _log('🔘 Login button pressed');
    
    final isValid = _formKey.currentState?.validate() ?? false;
    _log('📝 Form validation: ${isValid ? "PASSED" : "FAILED"}');
    
    if (isValid) {
      final email = _emailController.text.trim();
      _log('📧 Email: $email');
      _log('🔑 Password: ***HIDDEN*** (length: ${_passwordController.text.length})');
      _log('📤 Calling login API...');
      
      ref.read(authNotifierProvider.notifier).login(
            email: email,
            password: _passwordController.text,
          );
    } else {
      _log('⚠️ Form validation failed, not submitting');
    }
  }

  void _handleOAuthLogin(OAuthProvider provider) {
    _log('🔘 OAuth login pressed: $provider');
    ref.read(authNotifierProvider.notifier).loginWithOAuth(provider);
  }
}
