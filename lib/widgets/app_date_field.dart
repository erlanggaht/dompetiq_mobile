import 'package:flutter/material.dart';

import 'app_select_field.dart';

class AppDateField extends StatelessWidget {
  final String label;
  final String? valueLabel;
  final VoidCallback onTap;
  final bool enabled;

  const AppDateField({
    super.key,
    this.label = 'Date',
    this.valueLabel,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => AppSelectField<DateTime>(
    label: label,
    valueLabel: valueLabel,
    prefixIcon: Icons.calendar_today_outlined,
    onTap: onTap,
    enabled: enabled,
  );
}
