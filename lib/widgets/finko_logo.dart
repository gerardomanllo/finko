import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Square app mark from [assetPath].
class FinkoLogo extends StatelessWidget {
  const FinkoLogo({super.key, this.size = 88});

  static const String assetPath = 'assets/images/app_logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.appTitle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
