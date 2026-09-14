/// Global application constants.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Reunitee';
  static const String appNameAr = 'رونيتي';
  static const String packageName = 'com.reunitee.app';

  /// Base URL for the future REST backend.
  static const String apiBaseUrl = 'https://backend-node-three-omega.vercel.app/api';

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 20000;

  /// Configurable alert radius options in meters.
  static const List<int> alertRadiusOptions = [1000, 3000, 5000, 10000];
  static const int defaultAlertRadiusMeters = 3000;

  /// Fallback map center (Cairo) used before a location is granted.
  static const double defaultMapLat = 30.0444;
  static const double defaultMapLng = 31.2357;

  // Hive boxes.
  static const String hiveAuthBox = 'auth_box';
  static const String hivePrefsBox = 'prefs_box';
  static const String hiveCacheBox = 'cache_box';

  // Cache keys.
  static const String cacheRecentSearches = 'recent_searches';
  static const String cacheMissingCases = 'cached_missing_cases';
  static const String cacheNotifications = 'cached_notifications';

  static const int pageSize = 12;
  static const int debounceSearchMs = 350;
  static const int mockNetworkDelayMs = 700;
}