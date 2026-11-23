import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _primary = Color(0xFF3B62FF);
const _border = Color(0xFFE4E7EC);

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool enabled;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.enabled = true,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    readOnly: readOnly,
    onTap: onTap,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF2F4F7),
      labelStyle: TextStyle(color: enabled ? null : const Color(0xFF98A2B3)),
      hintStyle: TextStyle(color: enabled ? null : const Color(0xFF98A2B3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _borderStyle(_border),
      enabledBorder: _borderStyle(_border),
      focusedBorder: _borderStyle(_primary, width: 1.5),
      errorBorder: _borderStyle(const Color(0xFFDC2626)),
      focusedErrorBorder: _borderStyle(const Color(0xFFDC2626)),
    ),
  );

  OutlineInputBorder _borderStyle(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
