import 'package:flutter/material.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/device_id.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/change_pin_screen.dart';
import 'package:flutter_application_1/screens/edit_profile_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/app_page_header.dart';
import 'package:flutter_application_1/widgets/confirm_logout_dialog.dart';
import 'package:flutter_application_1/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _username = '';
  String? _avatar;
  bool _isSigningOut = false;

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
        _name = (data['fullName'] as String?) ?? '';
        _username = (data['username'] as String?) ?? '';
        _avatar = StorageConfig.avatarUrl(data['avatar'] as String?);
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _editProfile() async {
    try {
      final profile = await UserService.me();
      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
      );
      if (saved == true && mounted) _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _logout() async {
    if (!await confirmLogout(context)) return;

    setState(() => _isSigningOut = true);
    await AuthService().logout(deviceId: await DeviceId.get());
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.isEmpty ? 'DompetIQ' : _name;
    final username = formatUsername(_username);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 0, 36, 120),
          child: Column(
            children: [
              AppPageHeader(title: 'Profile', onBack: widget.onBack),
              const SizedBox(height: 28),
              ProfileAvatar(
                imageUrl: _avatar,
                name: name,
                radius: 34,
                backgroundColor: const Color(0xFFF2F4F7),
                initialFontSize: 28,
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                username,
                style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 14),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 146,
                height: 44,
                child: FilledButton(
                  onPressed: _editProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B62FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Divider(color: Color(0xFFE4E7EC), height: 1),
              _ProfileMenuTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: _comingSoon,
              ),
              _ProfileMenuTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                onTap: _comingSoon,
              ),
              _ProfileMenuTile(
                icon: Icons.pin_outlined,
                title: 'Change PIN',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePinScreen()),
                ),
              ),
              const Divider(color: Color(0xFFE4E7EC), height: 1),
              _ProfileMenuTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                danger: true,
                onTap: _isSigningOut ? null : _logout,
                trailing: _isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is not available yet')),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFD92D20) : const Color(0xFF101828);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 60,
      leading: Icon(icon, color: color, size: 21),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: color),
      onTap: onTap,
    );
  }
}
