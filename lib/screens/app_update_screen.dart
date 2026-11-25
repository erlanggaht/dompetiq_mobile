import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateScreen extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String updateUrl;
  final String? releaseNotes;

  const AppUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateUrl,
    this.releaseNotes,
  });

  Future<void> _openUpdate(BuildContext context) async {
    final uri = Uri.tryParse(updateUrl);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the update link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.downloadSimple,
                      size: 44,
                      color: Color(0xFF3B62FF),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Update available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A new version of DompetIQ ($latestVersion) is available. You are currently using version $currentVersion. Please update to continue.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (releaseNotes != null &&
                      releaseNotes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: Text(
                        releaseNotes!,
                        style: const TextStyle(
                          color: Color(0xFF344054),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => _openUpdate(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B62FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Update now',
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
        ),
      ),
    );
  }
}
