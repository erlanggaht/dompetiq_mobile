class BudgetPeriod {
  final int id;
  final String name;
  final String periodType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalAllocated;
  final int totalSpent;
  final List<BudgetItem> items;

  BudgetPeriod({
    required this.id,
    required this.name,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.totalAllocated,
    required this.totalSpent,
    required this.items,
  });

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) => BudgetPeriod(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    periodType: json['periodType'] as String? ?? 'monthly',
    startDate: DateTime.tryParse(json['startDate'] as String? ?? '')?.toLocal(),
    endDate: DateTime.tryParse(json['endDate'] as String? ?? '')?.toLocal(),
    totalAllocated: (json['totalAllocated'] as num?)?.toInt() ?? 0,
    totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
    items: (json['items'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BudgetItem.fromJson)
        .toList(),
  );
}

class BudgetItem {
  final int id;
  final int categoryUserId;
  final int allocated;
  final int spent;
  final int remaining;
  final String categoryName;

  BudgetItem({
    required this.id,
    required this.categoryUserId,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.categoryName,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
    id: (json['id'] as num).toInt(),
    categoryUserId: (json['categoryUserId'] as num?)?.toInt() ?? 0,
    allocated: (json['allocated'] as num?)?.toInt() ?? 0,
    spent: (json['spent'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
    categoryName: json['categoryName'] as String? ?? 'Category',
  );
}

BudgetPeriod? activeBudget(
  List<BudgetPeriod> periods, {
  String periodType = 'monthly',
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);

  for (final period in periods) {
    final start = period.startDate;
    final end = period.endDate;
    if (period.periodType != periodType || start == null || end == null) {
      continue;
    }
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (!today.isBefore(startDay) && !today.isAfter(endDay)) return period;
  }
  return null;
}
