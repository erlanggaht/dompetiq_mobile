import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/feat/savings/savings_service.dart';
import 'package:flutter_application_1/widgets/amount_field.dart';

/// Returns true when money was added successfully.
Future<bool> showSavingsTransferSheet({
  required BuildContext context,
  required Map<String, dynamic> goal,
  required List<Map<String, dynamic>> accounts,
  required SavingsService service,
}) async {
  if (accounts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No account with a card available')),
    );
    return false;
  }

  int? accountId = (accounts.first['id'] as num).toInt();
  final amount = TextEditingController();
  bool saving = false;
  bool showKeypad = true;
  final keys = AmountKeys(amount);

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.92,
    ),
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  showKeypad
                      ? 20
                      : MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add to ${goal['name']}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<int>(
                      initialValue: accountId,
                      decoration: const InputDecoration(
                        labelText: 'From account',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final account in accounts)
                          DropdownMenuItem<int>(
                            value: (account['id'] as num).toInt(),
                            child: Text(account['name'] as String),
                          ),
                      ],
                      onChanged: (value) => setSheet(() => accountId = value),
                    ),
                    const SizedBox(height: 14),
                    AmountField(
                      controller: amount,
                      useInternalKeypad: false,
                      autofocus: true,
                      onTap: () => setSheet(() => showKeypad = true),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final value =
                                    int.tryParse(
                                      amount.text.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      ),
                                    ) ??
                                    0;
                                if (value <= 0 || accountId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Choose an account and enter an amount',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setSheet(() => saving = true);
                                try {
                                  await service.transfer(
                                    goalId: (goal['id'] as num).toInt(),
                                    rekeningUserId: accountId!,
                                    amount: value,
                                    date: DateTime.now(),
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  setSheet(() => saving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: context.appColors.accent,
                        ),
                        child: Text(saving ? 'Saving...' : 'Add money'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showKeypad)
            AmountKeypad(
              fullWidth: true,
              onDigit: (digit) {
                keys.append(digit);
                setSheet(() {});
              },
              onBackspace: () {
                keys.backspace();
                setSheet(() {});
              },
              onQuickAmount: (value) {
                keys.set(value);
                setSheet(() {});
              },
              onDone: () => setSheet(() => showKeypad = false),
            ),
        ],
      ),
    ),
  );

  return result == true;
}
