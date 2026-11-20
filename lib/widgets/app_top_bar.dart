import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;
  final Color foreground;
  final bool hasUnreadNotifications;

  const AppTopBar({
    super.key,
    required this.title,
    this.onOpenMenu,
    this.onOpenNotifications,
    this.foreground = const Color(0xFF1C1C1C),
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onOpenMenu,
                icon: Icon(
                  PhosphorIconsRegular.list,
                  color: foreground,
                  size: 26,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onOpenNotifications,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      PhosphorIconsRegular.bell,
                      color: foreground,
                      size: 24,
                    ),
                    if (hasUnreadNotifications)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
