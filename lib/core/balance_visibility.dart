import 'package:flutter/foundation.dart';

class BalanceVisibility {
  static final ValueNotifier<bool> visible = ValueNotifier(true);

  static void toggle() => visible.value = !visible.value;
}
