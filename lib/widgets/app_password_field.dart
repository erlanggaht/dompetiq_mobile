import 'package:flutter/material.dart';

import 'app_text_field.dart';

class AppPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;

  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: widget.controller,
    label: widget.label,
    errorText: widget.errorText,
    prefixIcon: Icons.lock_outline,
    obscureText: !_visible,
    suffixIcon: IconButton(
      onPressed: () => setState(() => _visible = !_visible),
      icon: Icon(
        _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    ),
  );
}
