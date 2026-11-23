import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';

const _accent = Color(0xFF3B62FF);
const _ink = Color(0xFF111827);
const _muted = Color(0xFF8A90A2);
const _maxAmount = 2147483647;

class AmountKeys {
  final TextEditingController controller;

  const AmountKeys(this.controller);

  String get digits => controller.text.replaceAll(RegExp(r'[^0-9]'), '');

  void set(int amount) {
    final text = formatThousands(amount);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void append(String digit) {
    final current = digits;
    final next = current == '0' ? digit : '$current$digit';
    final amount = int.tryParse(next);
    if (amount == null || amount > _maxAmount) return;
    set(amount);
  }

  void backspace() {
    final current = digits;
    final next = current.length <= 1
        ? '0'
        : current.substring(0, current.length - 1);
    set(int.parse(next));
  }
}

class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback? onChanged;
  final VoidCallback? onTap;
  final bool useInternalKeypad;
  final bool autofocus;

  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.onChanged,
    this.onTap,
    this.useInternalKeypad = true,
    this.autofocus = false,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _focus = FocusNode();
  bool _showKeypad = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String get _digits =>
      widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');

  void _setAmount(int amount) {
    final text = formatThousands(amount);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call();
  }

  void _append(String digit) {
    final current = _digits;
    final next = current == '0' ? digit : '$current$digit';
    final amount = int.tryParse(next);
    if (amount == null || amount > _maxAmount) return;
    _setAmount(amount);
  }

  void _backspace() {
    final current = _digits;
    final next = current.length <= 1
        ? '0'
        : current.substring(0, current.length - 1);
    _setAmount(int.parse(next));
  }

  void _closeKeypad() {
    setState(() => _showKeypad = false);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            color: _muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 6),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                showCursor: !kIsWeb,
                readOnly: !kIsWeb,
                keyboardType: kIsWeb
                    ? TextInputType.number
                    : TextInputType.none,
                inputFormatters: [ThousandsFormatter()],
                cursorColor: _accent,
                onTap: kIsWeb
                    ? null
                    : widget.onTap ?? () => setState(() => _showKeypad = true),
                onChanged: (_) => widget.onChanged?.call(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.6,
                  height: 1.2,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (kIsWeb)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in const [50000, 100000, 500000, 1000000])
                ActionChip(
                  label: Text('Rp ${formatThousands(amount)}'),
                  onPressed: () => _setAmount(amount),
                ),
            ],
          )
        else if (_showKeypad && widget.useInternalKeypad)
          AmountKeypad(
            onDigit: _append,
            onBackspace: _backspace,
            onQuickAmount: _setAmount,
            onDone: _closeKeypad,
          ),
      ],
    );
  }
}

class AmountKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final ValueChanged<int> onQuickAmount;
  final VoidCallback onDone;
  final bool fullWidth;

  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onQuickAmount,
    required this.onDone,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final keys = Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            _quickButton(50000),
            _quickButton(100000),
            _quickButton(500000),
            _quickButton(1000000),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
              _key(digit, () => onDigit(digit)),
            _key(null, onBackspace, icon: PhosphorIconsRegular.backspace),
            _key('0', () => onDigit('0')),
            _key(null, onDone, icon: PhosphorIconsBold.check, color: _accent),
          ],
        ),
      ],
    );
    if (fullWidth) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF2F4F8),
            border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
          ),
          child: keys,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: keys,
    );
  }

  Widget _quickButton(int amount) {
    return InkWell(
      onTap: () => onQuickAmount(amount),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Text(
          'Rp ${formatThousands(amount)}',
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _key(
    String? label,
    VoidCallback onTap, {
    IconData? icon,
    Color color = _ink,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: icon == null
              ? Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    final amount = int.tryParse(digits);
    if (amount == null || amount > _maxAmount) return oldValue;
    final formatted = formatThousands(amount);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
