import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/app_theme.dart';

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? initialColor;
  final double initialFontSize;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.radius,
    this.backgroundColor,
    this.initialColor,
    this.initialFontSize = 26,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _failedUrl;

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _failedUrl = null;
  }

  bool get _hasImage =>
      widget.imageUrl != null && widget.imageUrl != _failedUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trimmed = widget.name.trim();
    final initial = trimmed.isEmpty ? 'D' : trimmed[0].toUpperCase();

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? colors.border,
      backgroundImage: _hasImage ? NetworkImage(widget.imageUrl!) : null,
      onBackgroundImageError: _hasImage
          ? (_, _) => setState(() => _failedUrl = widget.imageUrl)
          : null,
      child: _hasImage
          ? null
          : Text(
              initial,
              style: TextStyle(
                fontSize: widget.initialFontSize,
                fontWeight: FontWeight.w700,
                color: widget.initialColor ?? colors.accent,
              ),
            ),
    );
  }
}
