import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppBottomNav extends StatelessWidget {
  final VoidCallback? onHome;
  final VoidCallback? onTransactions;
  final VoidCallback? onAdd;
  final VoidCallback? onBudget;
  final VoidCallback? onProfile;

  const AppBottomNav({
    super.key,
    this.onHome,
    this.onTransactions,
    this.onAdd,
    this.onBudget,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _item(PhosphorIconsRegular.house, onHome),
          _item(PhosphorIconsRegular.receipt, onTransactions),
          Expanded(
            child: Center(
              child: IconButton(
                onPressed: onAdd,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3B62FF),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(50, 50),
                ),
                icon: const Icon(PhosphorIconsRegular.plus),
              ),
            ),
          ),
          _item(PhosphorIconsRegular.chartPieSlice, onBudget),
          _item(PhosphorIconsRegular.user, onProfile),
        ],
      ),
    ),
  );

  Widget _item(IconData icon, VoidCallback? onTap) => Expanded(
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF8A90A2)),
    ),
  );
}
