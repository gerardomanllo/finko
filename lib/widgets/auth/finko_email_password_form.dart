import 'package:flutter/material.dart';

/// Email + password fields, primary submit, register toggle, and inline error.
class FinkoEmailPasswordForm extends StatelessWidget {
  const FinkoEmailPasswordForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailLabel,
    required this.passwordLabel,
    required this.validationRequired,
    required this.validationEmail,
    required this.validationPasswordLength,
    required this.primaryLabel,
    required this.toggleLabel,
    required this.onSubmit,
    required this.onToggleMode,
    this.errorText,
    this.busy = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String emailLabel;
  final String passwordLabel;
  final String validationRequired;
  final String validationEmail;
  final String validationPasswordLength;
  final String primaryLabel;
  final String toggleLabel;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final String? errorText;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: emailLabel),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return validationRequired;
              if (!s.contains('@')) return validationEmail;
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: passwordLabel),
            validator: (v) {
              if (v == null || v.isEmpty) return validationRequired;
              if (v.length < 6) return validationPasswordLength;
              return null;
            },
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(primaryLabel),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onToggleMode,
            child: Text(toggleLabel),
          ),
        ],
      ),
    );
  }
}
