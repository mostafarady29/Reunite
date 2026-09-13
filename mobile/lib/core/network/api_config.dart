/// Global switch to choose between mock and real backend.
///
/// Defaults to `true` so the app runs offline with demo data.
/// Run with a real API:
/// ```
/// flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.myserver.com/v1
/// ```
const bool kUseMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

/// Overrides [AppConstants.apiBaseUrl] when provided via --dart-define.
/// Empty means "use the compiled-in default".
const String kApiBaseUrlOverride = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);
