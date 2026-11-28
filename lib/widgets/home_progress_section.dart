import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/balance_visibility.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/category_style.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/budget/budget_model.dart';
import 'package:flutter_application_1/widgets/solid_icon_badge.dart';

const _tabs = ['Budget', 'Account', 'Savings'];

class HomeProgressSection extends StatefulWidget {
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> cards;
  final List<Map<String, dynamic>> savings;
  final VoidCallback? onOpenBudget;
  final VoidCallback? onOpenCards;
  final VoidCallback? onOpenSavings;
  final ValueChanged<Map<String, dynamic>>? onAddSavings;

  const HomeProgressSection({
    super.key,
    required this.budgets,
    required this.cards,
    required this.savings,
    this.onOpenBudget,
    this.onOpenCards,
    this.onOpenSavings,
    this.onAddSavings,
  });

  @override
  State<HomeProgressSection> createState() => _HomeProgressSectionState();
}

class _HomeProgressSectionState extends State<HomeProgressSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final periods = widget.budgets.map(BudgetPeriod.fromJson).toList();
    final period = activeBudget(periods);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _tabBar(),
        ),
        const SizedBox(height: 14),
        if (_tab == 0)
          _budgetTab(period)
        else if (_tab == 1)
          _accountTab()
        else
          _savingsTab(),
      ],
    );
  }

  Widget _tabBar() {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.border.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (index, label) in _tabs.indexed)
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _tab = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _tab == index ? colors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _tab == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _tab == index
                            ? Theme.of(context).colorScheme.onPrimary
                            : colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _budgetTab(BudgetPeriod? period) {
    final items = period?.items ?? <BudgetItem>[];
    if (items.isEmpty) {
      return _placeholder(
        icon: PhosphorIconsRegular.chartPie,
        title: 'No active budget',
        message: 'Create a monthly budget to track your progress here.',
      );
    }

    return _twoColumnPager(
      items: items,
      height: 178,
      cardBuilder: (item) =>
          _BudgetProgressCard(item: item, onTap: widget.onOpenBudget),
    );
  }

  Widget _accountTab() {
    final cards = widget.cards;
    if (cards.isEmpty) {
      return _placeholder(
        icon: PhosphorIconsRegular.creditCard,
        title: 'No cards yet',
        message: 'Add a card to see your account balance here.',
      );
    }

    return _twoColumnPager(
      items: cards,
      height: 140,
      cardBuilder: (card) =>
          _AccountProgressCard(card: card, onTap: widget.onOpenCards),
    );
  }

  Widget _savingsTab() {
    final goals = widget.savings;
    if (goals.isEmpty) {
      return _placeholder(
        icon: PhosphorIconsRegular.piggyBank,
        title: 'No savings goal yet',
        message: 'Create a savings goal to track your progress here.',
      );
    }

    return _twoColumnPager(
      items: goals,
      height: 178,
      cardBuilder: (goal) => _SavingsProgressCard(
        goal: goal,
        onTap: widget.onOpenSavings,
        onAdd: widget.onAddSavings == null
            ? null
            : () => widget.onAddSavings!(goal),
      ),
    );
  }

  Widget _twoColumnPager<T>({
    required List<T> items,
    required double height,
    required Widget Function(T item) cardBuilder,
  }) {
    final pageCount = (items.length / 2).ceil();

    return SizedBox(
      height: height,
      child: PageView.builder(
        key: ValueKey('${T}_${items.length}'),
        itemCount: pageCount,
        itemBuilder: (context, page) {
          final pageItems = items.skip(page * 2).take(2).toList();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var index = 0; index < 2; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: index < pageItems.length
                        ? cardBuilder(pageItems[index])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.border
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SolidIconBadge(icon: icon, color: colors.accent, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback? onTap;

  const _BudgetProgressCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = item.allocated == 0
        ? 0.0
        : (item.spent / item.allocated).clamp(0.0, 1.0);
    final over = item.remaining < 0;
    final accent = over
        ? colors.danger
        : ratio >= 0.8
        ? colors.accent
        : colors.accent;
    final icon =
        categoryStyle(item.categoryName)?.$1 ?? PhosphorIconsFill.chartPie;

    return _cardShell(
      context: context,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SolidIconBadge(icon: icon, color: colors.accent, size: 36),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.categoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _AmountText(item.spent),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.border,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            over
                ? '${(ratio * 100).round()}% of budget · Over'
                : '${(ratio * 100).round()}% of budget',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountProgressCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback? onTap;

  const _AccountProgressCard({required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _cardShell(
      context: context,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SolidIconBadge(
                icon: PhosphorIconsFill.creditCard,
                color: colors.accent,
                size: 36,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card['name'] as String? ?? 'Card',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _AmountText((card['saldo'] as num?)?.toInt() ?? 0),
        ],
      ),
    );
  }
}

class _SavingsProgressCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const _SavingsProgressCard({required this.goal, this.onTap, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final target = (goal['target'] as num?)?.toInt() ?? 0;
    final saved = (goal['saved'] as num?)?.toInt() ?? 0;
    final ratio = target == 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);

    return _cardShell(
      context: context,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SolidIconBadge(
                icon: PhosphorIconsFill.piggyBank,
                color: colors.accent,
                size: 36,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal['name'] as String? ?? 'Goal',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _AmountText(saved)),
              if (onAdd != null)
                GestureDetector(
                  onTap: onAdd,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.plus,
                      size: 16,
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.border,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(ratio * 100).round()}% of target',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  final int amount;

  const _AmountText(this.amount);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ValueListenableBuilder<bool>(
      valueListenable: BalanceVisibility.visible,
      builder: (context, visible, _) => Text(
        visible ? formatRupiah(amount) : '••••••',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.ink,
        ),
      ),
    );
  }
}

Widget _cardShell({
  required Widget child,
  required BuildContext context,
  VoidCallback? onTap,
}) {
  final card = Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? context.appColors.border
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: context.appColors.ink.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
  if (onTap == null) return card;
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: card,
  );
}
