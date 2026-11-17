import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String? _avatar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await UserService.me();
      if (!mounted) return;
      setState(() {
        _name =
            (data['fullName'] as String?) ??
            (data['username'] as String? ?? '');
        _avatar = StorageConfig.avatarUrl(data['avatar'] as String?);
      });
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.isEmpty ? 'DompetIQ' : _name;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileAvatar(imageUrl: _avatar, name: name, radius: 36),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Account settings coming soon',
              style: TextStyle(fontSize: 14, color: Color(0xFF87879D)),
            ),
          ],
        ),
      ),
    );
  }
}
