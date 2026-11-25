import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _categoryStyles = {
  'SALARY': (PhosphorIconsFill.briefcase, Color(0xFF3B62FF)),
  'BUSINESS': (PhosphorIconsFill.storefront, Color(0xFF6366F1)),
  'INVESTMENT': (PhosphorIconsFill.chartLineUp, Color(0xFF0D9488)),
  'OTHER_INCOME': (PhosphorIconsFill.wallet, Color(0xFF16A34A)),
  'FOOD': (PhosphorIconsFill.forkKnife, Color(0xFFF59E0B)),
  'SHOP': (PhosphorIconsFill.shoppingBag, Color(0xFFA855F7)),
  'TRAVEL': (PhosphorIconsFill.airplaneTakeoff, Color(0xFF06B6D4)),
  'EDUCATION': (PhosphorIconsFill.graduationCap, Color(0xFF8B5CF6)),
  'EMERGENCY': (PhosphorIconsFill.firstAidKit, Color(0xFFEF4444)),
  'OTHER_SPENDING': (PhosphorIconsFill.receipt, Color(0xFF64748B)),
};

(IconData, Color)? categoryStyle(String name) =>
    _categoryStyles[name.toUpperCase().replaceAll(' ', '_')];
