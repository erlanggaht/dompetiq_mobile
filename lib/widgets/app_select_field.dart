import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_theme.dart';

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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          suffixIcon: const Icon(Icons.keyboard_arrow_down),
          errorText: errorText,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          labelStyle: TextStyle(color: enabled ? null : colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: _border(colors.border),
          enabledBorder: _border(colors.border),
          focusedBorder: _border(colors.accent, width: 1.5),
          errorBorder: _border(colors.danger),
          focusedErrorBorder: _border(colors.danger),
        ),
        child: Text(
          valueLabel ?? 'Select $label',
          style: TextStyle(
            color: !enabled
                ? colors.grey
                : valueLabel == null
                ? colors.grey
                : colors.ink,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
