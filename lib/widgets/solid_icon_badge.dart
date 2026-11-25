import 'package:flutter/material.dart';

class SolidIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const SolidIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}
