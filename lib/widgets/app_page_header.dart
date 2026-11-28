import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_application_1/core/app_theme.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? trailing;

  const AppPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.ink;
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack ?? () => Navigator.pop(context),
                icon: const Icon(PhosphorIconsRegular.arrowLeft),
                color: color,
              ),
            ),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    );
  }
}
