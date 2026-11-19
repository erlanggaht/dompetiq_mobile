import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/widgets/profile_avatar.dart';

class AppTopBar extends StatefulWidget {
  final String title;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenProfile;
  final Color foreground;
  final Color avatarBackground;

  const AppTopBar({
    super.key,
    required this.title,
    this.onOpenMenu,
    this.onOpenProfile,
    this.foreground = const Color(0xFF1C1C1C),
    this.avatarBackground = const Color(0xFFEDF1FF),
  });

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  String? _avatar;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await UserService.me();
      if (!mounted) return;
      setState(() {
        _avatar = StorageConfig.avatarUrl(data['avatar'] as String?);
        _name =
            (data['fullName'] as String?) ??
            (data['username'] as String? ?? '');
      });
    } catch (_) {
      return;
    }
  }

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
                onPressed: widget.onOpenMenu,
                icon: Icon(
                  PhosphorIconsRegular.list,
                  color: widget.foreground,
                  size: 26,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: widget.onOpenProfile,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProfileAvatar(
                    imageUrl: _avatar,
                    name: _name,
                    radius: 19,
                    backgroundColor: widget.avatarBackground,
                    initialFontSize: 16,
                  ),
                  Positioned(
                    right: 0,
                    top: 2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.foreground,
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
