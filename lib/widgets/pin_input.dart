import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Input PIN: satu TextField tersembunyi menampung 4 digit, kotak-kotak hanya
// display. Pendekatan ini membuat backspace bekerja alami, termasuk saat
// kotak berikutnya masih kosong (4 TextField terpisah tidak bisa).
class PinInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool autoFocus;

  const PinInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.autoFocus = false,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focus.requestFocus();
      });
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.controller.text;
    return GestureDetector(
      // ketuk area kotak mana pun tetap membuka keyboard
      onTap: () => _focus.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // index == panjang PIN = posisi input berikutnya
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final hasDigit = i < pin.length;
              final isFocused = i == pin.length && _focus.hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 58,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: isFocused || hasDigit
                      ? Colors.white
                      : const Color(0xFFF2F4F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    width: 2,
                    color: isFocused
                        ? const Color(0xFF3B62FF)
                        : hasDigit
                        ? const Color(0xFF3B62FF).withValues(alpha: 0.35)
                        : const Color(0xFFE4E7F0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasDigit ? pin[i] : '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
              );
            }),
          ),
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 70,
              height: 64,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                onChanged: widget.onChanged,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
