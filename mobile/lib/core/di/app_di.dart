import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/location_service.dart';
import '../services/push_notification_service.dart';
import '../storage/stores.dart';

/// Central service locator. Feature repositories and mocks are registered by
/// each feature's own `di.dart` during app bootstrap.
final GetIt getIt = GetIt.instance;

/// Registers core cross-cutting services. Called once before runApp.
Future<void> initCoreDependencies() async {
  // Store singletons.
  getIt.registerLazySingleton<AuthStore>(() => AuthStore.of());
  getIt.registerLazySingleton<PrefsStore>(() => PrefsStore.of());
  getIt.registerLazySingleton<CacheStore>(() => CacheStore.of());

  // Services.
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService.instance);
  getIt.registerLazySingleton<LocationService>(() => GeolocatorLocationService());
  getIt.registerLazySingleton<PushNotificationService>(
    () => FcmPushNotificationService(),
  );

  // Let the API interceptor read tokens lazily.
  final AuthStore authStore = getIt<AuthStore>();
  setTokenReader(() => authStore.token);
  getIt.registerLazySingleton<ApiClient>(() => ApiClient.instance);
}