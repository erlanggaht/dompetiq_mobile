import 'package:flutter/material.dart';

class AppSelectField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String? valueLabel;
  final IconData? prefixIcon;
  final VoidCallback onTap;
  final String? errorText;
  final bool enabled;

  const AppSelectField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.valueLabel,
    this.prefixIcon,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: const Icon(Icons.keyboard_arrow_down),
        errorText: errorText,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF2F4F7),
        labelStyle: TextStyle(color: enabled ? null : const Color(0xFF98A2B3)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _border(const Color(0xFFE4E7EC)),
        enabledBorder: _border(const Color(0xFFE4E7EC)),
        focusedBorder: _border(const Color(0xFF3B62FF), width: 1.5),
        errorBorder: _border(const Color(0xFFDC2626)),
        focusedErrorBorder: _border(const Color(0xFFDC2626)),
      ),
      child: Text(
        valueLabel ?? 'Select $label',
        style: TextStyle(
          color: !enabled
              ? const Color(0xFF98A2B3)
              : valueLabel == null
              ? const Color(0xFF98A2B3)
              : const Color(0xFF1C1C1C),
        ),
      ),
    ),
  );

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
