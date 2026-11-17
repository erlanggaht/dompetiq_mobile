import 'package:flutter/material.dart';

class HomeActionCard extends StatelessWidget {
  final VoidCallback onIncome;
  final VoidCallback onSpending;
  final VoidCallback onTransfer;

  const HomeActionCard({
    super.key,
    required this.onIncome,
    required this.onSpending,
    required this.onTransfer,
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
              icon: Icons.trending_up_rounded,
              label: 'Income',
              color: const Color(0xFF16A34A),
              onTap: onIncome,
            ),
            _divider(),
            _ActionItem(
              icon: Icons.trending_down_rounded,
              label: 'Spending',
              color: const Color(0xFFDC2626),
              onTap: onSpending,
            ),
            _divider(),
            _ActionItem(
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer',
              color: const Color(0xFF3B62FF),
              onTap: onTransfer,
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
                    shape: BoxShape.circle,
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
