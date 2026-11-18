import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/device_id.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/change_pin_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/confirm_logout_dialog.dart';
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
    if (!await confirmLogout(context, actionLabel: 'Sign out')) return;

    setState(() => _isSigningOut = true);
    await AuthService().logout(deviceId: await DeviceId.get());
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _comingSoon(String title) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title is not available yet')));
  }

  void _openPin() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePinScreen()),
    );
  }

  void _showAbout() {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'DompetIQ',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Personal finance management',
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
              _DrawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => _comingSoon('Settings'),
              ),
              _DrawerItem(
                icon: Icons.security_outlined,
                title: 'Security',
                onTap: _openPin,
              ),
              _DrawerItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () => _comingSoon('Help & Support'),
              ),
              _DrawerItem(
                icon: Icons.info_outline_rounded,
                title: 'About DompetIQ',
                onTap: _showAbout,
              ),
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF667085), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1C1C1C),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF667085),
      ),
      onTap: onTap,
    );
  }
}
