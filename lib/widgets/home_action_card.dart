import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_application_1/widgets/solid_icon_badge.dart';
import 'package:flutter_application_1/core/app_theme.dart';

class HomeActionCard extends StatelessWidget {
  final VoidCallback onIncome;
  final VoidCallback onSpending;
  final VoidCallback onTools;

  const HomeActionCard({
    super.key,
    required this.onIncome,
    required this.onSpending,
    required this.onTools,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.border
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _ActionItem(
              icon: PhosphorIconsFill.trendUp,
              label: 'Income',
              color: colors.accent,
              onTap: onIncome,
            ),
            _divider(context),
            _ActionItem(
              icon: PhosphorIconsFill.trendDown,
              label: 'Spending',
              color: colors.accent,
              onTap: onSpending,
            ),
            _divider(context),
            _ActionItem(
              icon: PhosphorIconsFill.squaresFour,
              label: 'Other',
              color: colors.accent,
              onTap: onTools,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 40, color: context.appColors.border);
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                SolidIconBadge(icon: icon, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.ink,
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
