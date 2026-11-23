import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/screens/budget_screen.dart';
import 'package:flutter_application_1/screens/report_screen.dart';
import 'package:flutter_application_1/screens/savings_screen.dart';
import 'package:flutter_application_1/screens/transactions_screen.dart';
import 'package:flutter_application_1/widgets/app_section_header.dart';

class ToolsScreen extends StatelessWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final bool hasUnreadNotifications;
  final VoidCallback? onOpenTransactions;
  final VoidCallback? onOpenBudget;
  final VoidCallback? onOpenSavings;
  final VoidCallback? onOpenReport;

  const ToolsScreen({
    super.key,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.hasUnreadNotifications = false,
    this.onOpenTransactions,
    this.onOpenBudget,
    this.onOpenSavings,
    this.onOpenReport,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _Tool(
        'Transactions',
        PhosphorIconsRegular.receipt,
        onOpenTransactions == null
            ? TransactionsScreen(
                onOpenMenu: onOpenMenu,
                onOpenNotifications: onOpenNotifications,
                hasUnreadNotifications: hasUnreadNotifications,
                showBottomNav: true,
              )
            : null,
        onTap: onOpenTransactions,
      ),
      _Tool(
        'Budget',
        PhosphorIconsRegular.chartPieSlice,
        onOpenBudget == null
            ? BudgetScreen(
                onOpenMenu: onOpenMenu,
                onOpenNotifications: onOpenNotifications,
                hasUnreadNotifications: hasUnreadNotifications,
                showBottomNav: true,
              )
            : null,
        onTap: onOpenBudget,
      ),
      _Tool(
        'Savings Goals',
        PhosphorIconsRegular.piggyBank,
        onOpenSavings == null
            ? SavingsScreen(
                onOpenMenu: onOpenMenu,
                onOpenNotifications: onOpenNotifications,
                hasUnreadNotifications: hasUnreadNotifications,
                showBottomNav: true,
              )
            : null,
        onTap: onOpenSavings,
      ),
      _Tool(
        'Monthly Report',
        PhosphorIconsRegular.chartLineUp,
        onOpenReport == null
            ? ReportScreen(
                onOpenMenu: onOpenMenu,
                onOpenNotifications: onOpenNotifications,
                hasUnreadNotifications: hasUnreadNotifications,
                showBottomNav: true,
              )
            : null,
        onTap: onOpenReport,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            AppSectionHeader(
              title: 'Tools',
              onOpenMenu: onOpenMenu,
              onOpenNotifications: onOpenNotifications,
              hasUnreadNotifications: hasUnreadNotifications,
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ToolCard(
                    item: item,
                    onTap: item.page == null && item.onTap == null
                        ? null
                        : item.onTap ??
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => item.page!),
                              ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tool {
  final String title;
  final IconData icon;
  final Widget? page;
  final VoidCallback? onTap;

  const _Tool(this.title, this.icon, this.page, {this.onTap});
}

class _ToolCard extends StatelessWidget {
  final _Tool item;
  final VoidCallback? onTap;

  const _ToolCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 28, color: const Color(0xFF3B62FF)),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
