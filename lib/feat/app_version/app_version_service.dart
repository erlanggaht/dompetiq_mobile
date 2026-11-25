import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum AppUpdateStatus { upToDate, optional, required }

class AppVersionInfo {
  final AppUpdateStatus status;
  final String currentVersion;
  final String latestVersion;
  final String minSupportedVersion;
  final String updateUrl;
  final String? releaseNotes;

  const AppVersionInfo({
    required this.status,
    required this.currentVersion,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.updateUrl,
    this.releaseNotes,
  });
}

class AppVersionService {
  final Dio _dio = DioClient.instance;

  Future<AppVersionInfo?> check({String platform = 'android'}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final response = await _dio.get(
        ApiRouteConfig.appVersion,
        queryParameters: {'platform': platform},
      );
      final data = (response.data['data'] as Map).cast<String, dynamic>();
      final latestVersion = '${data['latestVersion'] ?? ''}';
      final minSupportedVersion = '${data['minSupportedVersion'] ?? ''}';
      final updateUrl = '${data['updateUrl'] ?? ''}';
      final forceUpdate = data['forceUpdate'] == true;

      final status = _status(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        minSupportedVersion: minSupportedVersion,
        forceUpdate: forceUpdate,
      );

      return AppVersionInfo(
        status: status,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        minSupportedVersion: minSupportedVersion,
        updateUrl: updateUrl,
        releaseNotes: data['releaseNotes'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static AppUpdateStatus _status({
    required String currentVersion,
    required String latestVersion,
    required String minSupportedVersion,
    required bool forceUpdate,
  }) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(latestVersion);
    final minSupported = _parseVersion(minSupportedVersion);

    if (_isLower(current, minSupported) ||
        (forceUpdate && _isLower(current, latest))) {
      return AppUpdateStatus.required;
    }
    if (_isLower(current, latest)) {
      return AppUpdateStatus.optional;
    }
    return AppUpdateStatus.upToDate;
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map(
          (part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        )
        .toList();
  }

  static bool _isLower(List<int> a, List<int> b) {
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai < bi) return true;
      if (ai > bi) return false;
    }
    return false;
  }
}
