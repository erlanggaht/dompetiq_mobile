import 'package:flutter/material.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const AppPageHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFF101828),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
