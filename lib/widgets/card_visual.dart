import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/format.dart';

class CardVisual extends StatelessWidget {
  final String name;
  final String last4;
  final int saldo;
  final bool isActive;
  final int index;
  final bool compact;

  const CardVisual({
    super.key,
    required this.name,
    required this.last4,
    required this.saldo,
    required this.isActive,
    this.index = 0,
    this.compact = false,
  });

  static const _gradients = [
    [Color(0xFF3B62FF), Color(0xFF9B51E0)],
    [Color(0xFFFF6B8B), Color(0xFFFF9A6B)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFF232526), Color(0xFF414345)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[index % _gradients.length];
    if (compact) {
      return Row(
        children: [
          Container(
            width: 48,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: colors),
            ),
            child: const Icon(
              PhosphorIconsFill.creditCard,
              color: Colors.white70,
              size: 14,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '•••• $last4 · ${formatRupiah(saldo)}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            const Text(
              'Inactive',
              style: TextStyle(color: Color(0xFF98A2B3), fontSize: 11),
            ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Opacity(
        opacity: isActive ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    PhosphorIconsFill.creditCard,
                    color: Colors.white70,
                    size: 22,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '•••• $last4',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatRupiah(saldo),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
