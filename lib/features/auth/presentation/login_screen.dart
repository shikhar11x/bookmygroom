import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../application/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final repo = ref.read(authRepositoryProvider);
    try {
      if (_isSignUp) {
        final signedIn = await repo.signUp(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
        if (!signedIn && mounted) {
          setState(() {
            _info = 'Check your email to confirm your account, then sign in.';
            _isSignUp = false;
          });
        }
      } else {
        await repo.signIn(email: _email.text.trim(), password: _password.text);
      }
      // On success the router redirects automatically.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xxl,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            Text('BOOKMYGROOM', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isSignUp ? 'Create your\naccount' : 'Welcome\nback',
              style: theme.textTheme.displayLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'Full name'),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(hintText: 'Email'),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                          ? null
                          : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Use at least 8 characters'
                        : null,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            if (_info != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _info!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _isSignUp ? 'Create account' : 'Sign in',
              isLoading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                        _info = null;
                      }),
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
