import 'package:flutter/material.dart';

import 'package:flutter_application_1/widgets/app_top_bar.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final bool hasUnreadNotifications;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: AppTopBar(
        title: title,
        onOpenMenu: onOpenMenu,
        onOpenNotifications: onOpenNotifications,
        hasUnreadNotifications: hasUnreadNotifications,
      ),
    );
  }
}
