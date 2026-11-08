import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/app_logo.dart';
import '../data/mock_auth_repository.dart';
import '../domain/user_role.dart';
import 'auth_controller.dart';

/// Sign-in screen that also lets new applicants create an account.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _registering = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_registering) {
      widget.auth.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
    } else {
      widget.auth.signIn(_email.text, _password.text);
    }
  }

  void _toggleMode() {
    widget.auth.clearError();
    setState(() => _registering = !_registering);
  }

  void _fillDemo(UserRole role) {
    _email.text = MockAuthRepository.demoEmail(role);
    _password.text = MockAuthRepository.demoPassword;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.auth,
                builder: (context, _) {
                  final busy = widget.auth.isBusy;
                  final error = widget.auth.error;
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(size: 72)),
                        const SizedBox(height: 16),
                        Text(
                          kUniversityName,
                          textAlign: TextAlign.center,
                          style: text.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _registering
                              ? context.tr('Create your applicant account')
                              : context.tr('Sign in to your campus portal'),
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_registering) ...[
                          TextFormField(
                            controller: _name,
                            enabled: !busy,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: context.tr('Full name'),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? context.tr('Enter your full name.')
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _email,
                          enabled: !busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: _registering
                                ? context.tr('Email address')
                                : context.tr('University email'),
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? context.tr('Enter a valid email address.')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !busy,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: context.tr('Password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? context.tr('Show password')
                                  : context.tr('Hide password'),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? context.tr(
                                  'Password must be at least 6 characters.',
                                )
                              : null,
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.tr(error),
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          child: busy
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _registering
                                      ? context.tr('Create account')
                                      : context.tr('Sign in'),
                                ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: busy ? null : _toggleMode,
                          child: Text(
                            _registering
                                ? context.tr('Already have an account? Sign in')
                                : context.tr(
                                    'New applicant? Create an account',
                                  ),
                          ),
                        ),
                        if (kDebugMode &&
                            widget.auth.showDemoAccounts &&
                            !_registering) ...[
                          const SizedBox(height: 24),
                          Text(
                            context.tr('Demo accounts (debug builds only)'),
                            style: text.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final role in UserRole.values)
                                ActionChip(
                                  avatar: Icon(role.icon, size: 18),
                                  label: Text(context.tr(role.label)),
                                  onPressed: busy
                                      ? null
                                      : () => _fillDemo(role),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
