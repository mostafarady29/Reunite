/// REST endpoint paths. The base URL lives in [AppConstants.apiBaseUrl]
/// (overridable at compile time via `--dart-define=API_BASE_URL=...`).
class ApiEndpoints {
  const ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String requestReset = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String updateProfile = '/auth/profile';

  // Cases / reports
  static const String missingCases = '/cases/missing';
  static const String foundCases = '/cases/found';
  static const String statistics = '/cases/statistics';
  static const String nearby = '/cases/nearby';
  static String caseById(String id) => '/cases/$id';
  static String possibleMatches(String id) => '/cases/$id/matches';
  static const String sightings = '/sightings';
  static const String submitMissing = '/cases/missing';
  static const String submitFound = '/cases/found';
  static const String myReports = '/me/reports';
  static const String myFindings = '/me/findings';
  static const String mySightings = '/me/sightings';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String registerDeviceToken = '/notifications/device-token';

  // Locations (governorates + cities for dropdowns)
  static const String governorates = '/locations/governorates';
}
