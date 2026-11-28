import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/device_id.dart';
import 'package:flutter_application_1/core/network/server_error.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/auth/login_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/edit_profile_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/settings_screen.dart';
import 'package:flutter_application_1/widgets/app_page_header.dart';
import 'package:flutter_application_1/widgets/confirm_logout_dialog.dart';
import 'package:flutter_application_1/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onDataReset;
  final ValueChanged<bool>? onServerError;

  const ProfileScreen({super.key, this.onDataReset, this.onServerError});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _username = '';
  String? _avatar;
  bool _isSigningOut = false;
  bool _loading = true;
  bool _hasData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_hasData) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await UserService.me();
      if (!mounted) return;
      setState(() {
        _name = (data['fullName'] as String?) ?? '';
        _username = (data['username'] as String?) ?? '';
        _avatar = StorageConfig.avatarUrl(data['avatar'] as String?);
        _loading = false;
        _hasData = true;
        _error = null;
      });
      widget.onServerError?.call(false);
    } catch (e) {
      if (!mounted) return;
      final serverError = isServerConnectionError(e);
      widget.onServerError?.call(serverError);
      if (_hasData) {
        setState(() => _loading = false);
      } else {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> reload() => _load();

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
    final colors = context.appColors;
    final name = _name.isEmpty ? 'DompetIQ' : _name;
    final username = formatUsername(_username);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _loading && !_hasData
            ? const Center(child: CircularProgressIndicator())
            : _error != null && !_hasData
            ? Column(
                children: [
                  const AppPageHeader(title: 'Profile', showBack: false),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(36, 0, 36, 120),
                child: Column(
                  children: [
                    const AppPageHeader(title: 'Profile', showBack: false),
                    const SizedBox(height: 28),
                    ProfileAvatar(
                      imageUrl: _avatar,
                      name: name,
                      radius: 34,
                      backgroundColor: colors.border,
                      initialFontSize: 28,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      username,
                      style: TextStyle(color: colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: 146,
                      height: 44,
                      child: FilledButton(
                        onPressed: _editProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accent,
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
                    Divider(color: colors.border, height: 1),
                    _ProfileMenuTile(
                      icon: PhosphorIconsRegular.gear,
                      title: 'Settings',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SettingsScreen(onDataReset: widget.onDataReset),
                        ),
                      ),
                    ),
                    Divider(color: colors.border, height: 1),
                    _ProfileMenuTile(
                      icon: PhosphorIconsRegular.signOut,
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
    final color = danger ? context.appColors.danger : context.appColors.ink;
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
      trailing: trailing ?? Icon(PhosphorIconsRegular.caretRight, color: color),
      onTap: onTap,
    );
  }
}
