import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/device_id.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/profile_avatar.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _name = '';
  String _email = '';
  String? _avatar;
  bool _isSigningOut = false;

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
        _name =
            (data['fullName'] as String?) ??
            (data['username'] as String? ?? '');
        _email = (data['email'] as String?) ?? '';
        _avatar = StorageConfig.avatarUrl(data['avatar'] as String?);
      });
      debugPrint(data.toString());
    } on DioException {
      debugPrint('Failed to load profile');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSigningOut = true);
    await AuthService().logout(deviceId: await DeviceId.get());
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    imageUrl: _avatar,
                    name: _name.isEmpty ? 'DompetIQ' : _name,
                    radius: 34,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _name.isEmpty ? 'DompetIQ' : _name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1C),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _email,
                style: const TextStyle(fontSize: 14, color: Color(0xFF87879D)),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEDEEF3)),
              const SizedBox(height: 10),
              const Spacer(),
              SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: _isSigningOut ? null : _signOut,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F4F9),
                    foregroundColor: const Color(0xFF1C1C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isSigningOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Sign out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
