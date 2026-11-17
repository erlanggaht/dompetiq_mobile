import 'package:flutter/material.dart';

const _categoryStyles = {
  'SALARY': (Icons.work_outline, Color(0xFF3B62FF)),
  'BUSINESS': (Icons.storefront_outlined, Color(0xFF6366F1)),
  'INVESTMENT': (Icons.trending_up_rounded, Color(0xFF0D9488)),
  'OTHER_INCOME': (Icons.payments_outlined, Color(0xFF16A34A)),
  'FOOD': (Icons.restaurant_rounded, Color(0xFFF59E0B)),
  'SHOP': (Icons.shopping_bag_outlined, Color(0xFFA855F7)),
  'TRAVEL': (Icons.flight_takeoff_rounded, Color(0xFF06B6D4)),
  'EDUCATION': (Icons.school_outlined, Color(0xFF8B5CF6)),
  'EMERGENCY': (Icons.health_and_safety_outlined, Color(0xFFEF4444)),
  'OTHER_SPENDING': (Icons.receipt_outlined, Color(0xFF64748B)),
};

(IconData, Color)? categoryStyle(String name) =>
    _categoryStyles[name.toUpperCase().replaceAll(' ', '_')];
