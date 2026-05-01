import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty) {
      _showAlert('Validation', 'Username is required.');
      return;
    }
    if (password.isEmpty) {
      _showAlert('Validation', 'Password is required.');
      return;
    }

    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().login(email, password);
      if (mounted) context.go('/deliveries');
    } catch (e) {
      if (mounted) {
        _showAlert(
            'Could not sign in',
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // ── Hero gradient (matches LinearGradient in React Native) ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.gradientHero,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(22),
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery partner',
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use the delivery account issued by the pharmacy.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),

              // ── Login card ────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Username
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Username',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 10),

                    // Password
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.gray500,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 14),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.white),
                              )
                            : const Text('Sign in',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Close
                    GestureDetector(
                      onTap: _busy ? null : () => context.go('/deliveries'),
                      child: Text(
                        'Close',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
