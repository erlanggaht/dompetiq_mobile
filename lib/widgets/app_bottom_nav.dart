import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_application_1/core/app_theme.dart';

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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? colors.border
              : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _item(context, PhosphorIconsRegular.house, onHome),
            _item(context, PhosphorIconsRegular.receipt, onTransactions),
            Expanded(
              child: Center(
                child: IconButton(
                  onPressed: onAdd,
                  style: IconButton.styleFrom(
                    backgroundColor: context.appColors.accent,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    fixedSize: const Size(50, 50),
                  ),
                  icon: const Icon(PhosphorIconsRegular.plus),
                ),
              ),
            ),
            _item(context, PhosphorIconsRegular.chartPieSlice, onBudget),
            _item(context, PhosphorIconsRegular.user, onProfile),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, VoidCallback? onTap) =>
      Expanded(
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: context.appColors.grey),
        ),
      );
}
