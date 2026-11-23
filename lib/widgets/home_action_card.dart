import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              color: const Color(0xFF16A34A),
              onTap: onIncome,
            ),
            _divider(),
            _ActionItem(
              icon: PhosphorIconsFill.trendDown,
              label: 'Spending',
              color: const Color(0xFFDC2626),
              onTap: onSpending,
            ),
            _divider(),
            _ActionItem(
              icon: PhosphorIconsFill.squaresFour,
              label: 'Tools',
              color: const Color(0xFF3B62FF),
              onTap: onTools,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: const Color(0xFFEDEEF3));
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1C),
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
