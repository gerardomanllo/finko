import 'package:flutter/material.dart';

/// Google + Apple provider buttons per login spec.
class FinkoSocialAuthButtons extends StatelessWidget {
  const FinkoSocialAuthButtons({
    super.key,
    required this.onGoogle,
    required this.onApple,
    required this.googleLabel,
    required this.appleLabel,
    this.busy = false,
  });

  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final String googleLabel;
  final String appleLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: busy ? null : onGoogle,
          icon: const Icon(Icons.g_mobiledata, size: 24),
          label: Text(googleLabel),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : onApple,
          icon: const Icon(Icons.apple, size: 22),
          label: Text(appleLabel),
        ),
      ],
    );
  }
}
