class ApiRouteConfig {
  static const String login = '/auth/login';
  static const String loginPin = '/auth/login/pin';
  static const String loginCheck = '/auth/login/check';
  static const String logout = '/auth/logout';
  static const String register = '/auth/create-account';
  static const String rekenings = '/general/rekenings';
  static const String resetPasswordSend = '/auth/reset-password/send';
  static const String pinResetSend = '/auth/reset-pin/send';
  static const String limitDevice = '/auth/limit-device';
  static const String accountTransfers = '/account-transfers';
  static const String financialRecord = '/financial-record';
  static const String budget = '/budget';
  static const String categoryMe = '/general/categorys/me';
  static const String rekeningMe = '/general/rekenings/me';
  static const String securityPin = '/settings/security/pin';
  static const String changePassword = '/settings/security/password';
  static const String resetData = '/settings/reset';
  static const String deleteAccount = '/settings/delete-my-account';
  static const String usersMe = '/users/me';
  static const String monthlySummary = '/monthly-summary';
  static const String notifications = '/notifications';
}

class StorageConfig {
  static const String baseUrl = '${String.fromEnvironment('S3_URL')}/dompetiq';
  static int _avatarVersion = DateTime.now().millisecondsSinceEpoch;

  static String? avatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) {
      return '$path${path.contains('?') ? '&' : '?'}v=$_avatarVersion';
    }
    final url = '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
    return '$url?v=$_avatarVersion';
  }

  static void refreshAvatarCache() {
    _avatarVersion = DateTime.now().millisecondsSinceEpoch;
  }
}
