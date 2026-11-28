import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_application_1/core/biometric_lock.dart';
import 'package:flutter_application_1/core/app_theme.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/core/theme_mode_store.dart';
import 'package:flutter_application_1/feat/app_version/app_version_service.dart';
import 'package:flutter_application_1/feat/settings/delete_account_service.dart';
import 'package:flutter_application_1/feat/settings/reset_data_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/app_update_screen.dart';
import 'package:flutter_application_1/screens/change_password_screen.dart';
import 'package:flutter_application_1/screens/change_pin_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/app_page_header.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onDataReset;

  const SettingsScreen({super.key, this.onDataReset});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentVersion = '';
  bool _checkingUpdate = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final available = await BiometricLock.isAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (!available) return;
    final enabled = await BiometricLock.load();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_biometricBusy) return;
    setState(() => _biometricBusy = true);
    try {
      if (value) {
        final confirmed = await BiometricLock.authenticate(
          reason: 'Enable biometric lock',
        );
        if (!confirmed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication cancelled'),
              ),
            );
          }
          return;
        }
      }
      await BiometricLock.setEnabled(value);
      if (mounted) setState(() => _biometricEnabled = value);
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _currentVersion = info.version);
  }

  Future<void> _checkForUpdates() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    try {
      final info = await AppVersionService().check();
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to check for updates.')),
        );
        return;
      }
      if (info.status == AppUpdateStatus.required) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppUpdateScreen(
              currentVersion: info.currentVersion,
              latestVersion: info.latestVersion,
              updateUrl: info.updateUrl,
              releaseNotes: info.releaseNotes,
            ),
          ),
        );
        return;
      }
      if (info.status == AppUpdateStatus.optional) {
        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update available'),
            content: Text(
              'A new version of DompetIQ (${info.latestVersion}) is available. You are currently using version ${info.currentVersion}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Update'),
              ),
            ],
          ),
        );
        if (shouldUpdate == true) {
          final uri = Uri.tryParse(info.updateUrl);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DompetIQ is up to date ($_currentVersion).')),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title is not available yet')));
  }

  Future<void> _resetData(BuildContext context) async {
    final confirmationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canConfirm = confirmationController.text.trim() == 'reset data';
          return AlertDialog(
            title: const Text('Reset data?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'This will permanently delete your transactions, budgets, transfers, and saved tool data. This action cannot be undone.',
                ),
                const SizedBox(height: 18),
                const Text(
                  'Type "reset data" to continue',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmationController,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'reset data',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.danger,
                ),
                onPressed: canConfirm
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Reset data'),
              ),
            ],
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => confirmationController.dispose(),
    );
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ResetDataService().reset();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (context.mounted) Navigator.pop(context, true);
      widget.onDataReset?.call();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canConfirm =
              confirmationController.text.trim() == 'delete account';
          return AlertDialog(
            title: const Text('Delete account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'This will permanently delete your account and all its data: transactions, rekening, categories, cards, budgets, and profile. This action cannot be undone.',
                ),
                const SizedBox(height: 18),
                const Text(
                  'Type "delete account" to continue',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmationController,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'delete account',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.danger,
                ),
                onPressed: canConfirm
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Delete account'),
              ),
            ],
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => confirmationController.dispose(),
    );
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await DeleteAccountService().delete();
      UserService.clear();
      await BiometricLock.setEnabled(false);
      await DioClient.clearSession();
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeStore = ThemeModeStore.active;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
                children: [
                  const _SettingsSectionTitle('Security'),
                  _SettingsSwitchTile(
                    icon: PhosphorIconsRegular.fingerprint,
                    title: 'Biometric lock',
                    subtitle: _biometricAvailable
                        ? 'Unlock with fingerprint, face, or device PIN'
                        : 'Not available on this device',
                    value: _biometricEnabled,
                    onChanged: _biometricAvailable && !_biometricBusy
                        ? _toggleBiometric
                        : null,
                  ),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.lock,
                    title: 'Change Password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.password,
                    title: 'Change PIN',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePinScreen(),
                      ),
                    ),
                  ),
                  const _SettingsSectionTitle('Appearance'),
                  _ThemeModeSelector(store: themeStore),

                  const _SettingsSectionTitle('Data & Privacy'),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.trash,
                    title: 'Reset Data',
                    danger: true,
                    onTap: () => _resetData(context),
                  ),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.userCircleMinus,
                    title: 'Delete Account',
                    danger: true,
                    onTap: () => _deleteAccount(context),
                  ),
                  const _SettingsSectionTitle('About'),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.arrowClockwise,
                    title: 'Check for updates',
                    subtitle: _currentVersion.isEmpty
                        ? null
                        : 'Current version $_currentVersion',
                    trailing: _checkingUpdate
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _checkingUpdate ? null : _checkForUpdates,
                  ),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.info,
                    title: 'About DompetIQ',
                    onTap: () => _comingSoon(context, 'About DompetIQ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: context.appColors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeModeStore? store;

  const _ThemeModeSelector({required this.store});

  @override
  Widget build(BuildContext context) {
    final mode = store?.mode ?? ThemeMode.system;
    return _SettingsTile(
      icon: PhosphorIconsRegular.palette,
      title: 'Appearance',
      subtitle: _modeLabel(mode),
      onTap: store == null
          ? null
          : () async {
              final selected = await showDialog<ThemeMode>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Appearance'),
                  children: [
                    for (final option in ThemeMode.values)
                      ListTile(
                        title: Text(_modeLabel(option)),
                        trailing: option == mode
                            ? Icon(
                                PhosphorIconsRegular.check,
                                color: context.appColors.accent,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, option),
                      ),
                  ],
                ),
              );
              if (selected != null) await store!.setMode(selected);
            },
    );
  }

  String _modeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icon, color: colors.ink),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: const TextStyle(fontSize: 13)),
          value: value,
          activeTrackColor: colors.accent,
          onChanged: onChanged,
        ),
        Divider(color: colors.border, height: 1),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = danger ? colors.danger : colors.ink;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 60,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: const TextStyle(fontSize: 13)),
          trailing:
              trailing ?? Icon(PhosphorIconsRegular.caretRight, color: color),
          onTap: onTap,
        ),
        Divider(color: colors.border, height: 1),
      ],
    );
  }
}
