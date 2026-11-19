import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/widgets/app_top_bar.dart';

class HomeHeader extends StatelessWidget {
  final int balance;
  final int income;
  final int spending;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenProfile;

  const HomeHeader({
    super.key,
    required this.balance,
    required this.income,
    required this.spending,
    this.onOpenMenu,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B62FF), Color(0xFF2242D6)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              AppTopBar(
                title: 'DompetIQ',
                onOpenMenu: onOpenMenu,
                onOpenProfile: onOpenProfile,
                foreground: Colors.white,
                avatarBackground: Colors.white,
              ),
              const SizedBox(height: 36),
              const Text(
                'IDR',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<bool>(
                valueListenable: BalanceVisibility.visible,
                builder: (context, visible, _) => Column(
                  children: [
                    _BalanceRow(amount: balance, visible: visible),
                    const SizedBox(height: 10),
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SummaryItem(
                          label: 'Income',
                          amount: visible ? formatRupiah(income) : '••••••',
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          color: Colors.white24,
                        ),
                        _SummaryItem(
                          label: 'Spending',
                          amount: visible ? formatRupiah(spending) : '••••••',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 108),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final int amount;
  final bool visible;

  const _BalanceRow({required this.amount, required this.visible});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Toggle balance visibility',
      child: GestureDetector(
        onTap: () => BalanceVisibility.toggle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  visible ? formatRupiah(amount) : '••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    height: 1.25,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: IconButton(
                onPressed: () => BalanceVisibility.toggle(),
                icon: Icon(
                  visible
                      ? PhosphorIconsRegular.lockOpen
                      : PhosphorIconsRegular.lock,
                ),
                iconSize: 20,
                color: Colors.white70,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: visible ? 'Hide balance' : 'Show balance',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;

  const _SummaryItem({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
