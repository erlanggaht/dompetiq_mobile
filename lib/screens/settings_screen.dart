import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:flutter_application_1/feat/settings/delete_account_service.dart';
import 'package:flutter_application_1/feat/settings/reset_data_service.dart';
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/screens/change_password_screen.dart';
import 'package:flutter_application_1/screens/change_pin_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/widgets/app_page_header.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onDataReset;

  const SettingsScreen({super.key, this.onDataReset});

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
                  backgroundColor: const Color(0xFFD92D20),
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
      onDataReset?.call();
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
                  backgroundColor: const Color(0xFFD92D20),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
                children: [
                  const _SettingsSectionTitle('Security'),
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
                  const _SettingsSectionTitle('Notifications'),
                  _SettingsTile(
                    icon: PhosphorIconsRegular.bell,
                    title: 'Notifications',
                    onTap: () => _comingSoon(context, 'Notifications'),
                  ),
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
        style: const TextStyle(
          color: Color(0xFF667085),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFD92D20) : const Color(0xFF101828);
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
          trailing: Icon(PhosphorIconsRegular.caretRight, color: color),
          onTap: onTap,
        ),
        const Divider(color: Color(0xFFE4E7EC), height: 1),
      ],
    );
  }
}
