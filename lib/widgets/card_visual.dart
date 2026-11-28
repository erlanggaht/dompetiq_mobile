import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/app_theme.dart';

class CardVisual extends StatelessWidget {
  final String name;
  final String last4;
  final int saldo;
  final bool isActive;
  final int index;
  final bool compact;

  const CardVisual({
    super.key,
    required this.name,
    required this.last4,
    required this.saldo,
    required this.isActive,
    this.index = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final colors = [
      [appColors.accent, appColors.ink],
      [appColors.accent, appColors.grey],
      [appColors.green, appColors.accent],
      [appColors.ink, appColors.grey],
    ][index % 4];
    if (compact) {
      return Row(
        children: [
          Container(
            width: 48,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: colors),
            ),
            child: const Icon(
              PhosphorIconsFill.creditCard,
              color: Colors.white70,
              size: 14,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                ValueListenableBuilder<bool>(
                  valueListenable: BalanceVisibility.visible,
                  builder: (context, visible, _) => GestureDetector(
                    onTap: BalanceVisibility.toggle,
                    child: Text(
                      '•••• $last4 · ${visible ? formatRupiah(saldo) : '••••••'}',
                      style: TextStyle(color: appColors.grey, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            Text(
              'Inactive',
              style: TextStyle(color: appColors.grey, fontSize: 11),
            ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Opacity(
        opacity: isActive ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    PhosphorIconsFill.creditCard,
                    color: Colors.white70,
                    size: 22,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '•••• $last4',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<bool>(
                valueListenable: BalanceVisibility.visible,
                builder: (context, visible, _) => GestureDetector(
                  onTap: BalanceVisibility.toggle,
                  child: Text(
                    visible ? formatRupiah(saldo) : '••••••',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
