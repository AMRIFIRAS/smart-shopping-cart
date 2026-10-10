import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/app_session.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';

String authErrorMessage(Object error) {
  final code = error is AuthFailure ? error.code : '';
  return switch (code) {
    'not-configured' =>
      'Account setup is not complete yet. Continue shopping as a guest.',
    'invalid-email' => 'Please enter a valid email address.',
    'weak-password' => 'Password is too weak. Use at least 8 characters.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'The email or password is incorrect.',
    'email-already-in-use' =>
      'This email already has an account. Try signing in.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'network-request-failed' => 'Check your connection and try again.',
    'operation-not-allowed' =>
      'Email/password sign-in is not enabled for this project yet.',
    'user-disabled' => 'This account has been disabled.',
    _ => 'Account action failed. Please try again.',
  };
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.create = false, this.reset = false});
  final bool create;
  final bool reset;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool busy = false;
  String? feedback;
  bool success = false;
  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    final auth = SessionScope.of(context).auth;
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      if (widget.reset) {
        try {
          await auth.resetPassword(email.text);
        } on AuthFailure catch (error) {
          if (error.code != 'user-not-found') rethrow;
        }
        if (mounted) {
          setState(() {
            success = true;
            feedback = 'If an account exists for this email, a reset link has been sent.';
          });
        }
      } else {
        if (widget.create) {
          await auth.createAccount(email.text, password.text, name.text);
        } else {
          await auth.signIn(email.text, password.text);
        }
        if (mounted) Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          success = false;
          feedback = authErrorMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.reset
        ? 'Forgot Password'
        : widget.create
        ? 'Create Account'
        : 'Sign In';
    return Scaffold(
      appBar: AppBar(title: LText(title)),
      body: SafeArea(
        child: PageBody(
          maxWidth: 540,
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeading(
                  eyebrow: 'Make yourself at home',
                  title: title,
                  subtitle: widget.reset
                      ? 'Enter your email to receive a password reset link.'
                      : 'Shop freely. An account is always optional.',
                ),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!SessionScope.of(context).auth.isConfigured)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: InfoNote(
                            'Account setup is not complete yet. Continue shopping as a guest.',
                          ),
                        ),
                      if (widget.create)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            key: const Key('auth-name'),
                            controller: name,
                            maxLength: 60,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: context.tr('Display name (optional)'),
                            ),
                          ),
                        ),
                      TextFormField(
                        key: const Key('auth-email'),
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: context.tr('Email address'),
                        ),
                        validator: (value) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value?.trim() ?? '')
                            ? null
                            : context.tr('Please enter a valid email address.'),
                      ),
                      if (!widget.reset)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextFormField(
                            key: const Key('auth-password'),
                            controller: password,
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            textDirection: TextDirection.ltr,
                            autofillHints: [
                              widget.create
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: context.tr('Password'),
                              helperText: widget.create
                                  ? context.tr(
                                      'Use at least 8 characters for your password.',
                                    )
                                  : null,
                              helperMaxLines: 2,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr(
                                  'Please enter your password.',
                                );
                              }
                              if (widget.create && value.length < 8) {
                                return context.tr(
                                  'Password is too weak. Use at least 8 characters.',
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      const SizedBox(height: 22),
                      FilledButton(
                        key: const Key('auth-submit'),
                        onPressed: busy ? null : submit,
                        child: LText(
                          busy
                              ? 'Working…'
                              : widget.reset
                              ? 'Send reset link'
                              : title,
                        ),
                      ),
                      if (feedback != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: LText(
                              feedback!,
                              style: TextStyle(
                                color: success ? forest : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ),
                      if (!widget.reset && !widget.create)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AuthScreen(reset: true),
                                  ),
                                ),
                          child: const LText('Forgot Password'),
                        ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () =>
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst),
                        child: const LText('Continue as Guest'),
                      ),
                    ],
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
