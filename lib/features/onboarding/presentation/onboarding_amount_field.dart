import 'package:flutter/material.dart';

import 'onboarding_input_styles.dart';
import 'onboarding_money_parsing.dart';

/// Amount [TextField] that reformats on blur (whole majors without decimals) and uses a muted value style.
class OnboardingAmountTextField extends StatefulWidget {
  const OnboardingAmountTextField({
    super.key,
    required this.controller,
    required this.decoration,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.onChanged,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<OnboardingAmountTextField> createState() =>
      _OnboardingAmountTextFieldState();
}

class _OnboardingAmountTextFieldState extends State<OnboardingAmountTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final m = parseMajorToMinor(widget.controller.text) ?? 0;
      final formatted = formatMinorAsInputString(m);
      if (widget.controller.text != formatted) {
        widget.controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      style: onboardingAmountInputStyle(context),
      decoration: widget.decoration,
      onChanged: widget.onChanged,
    );
  }
}
