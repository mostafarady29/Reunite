import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/app_di.dart';
import 'core/di/feature_di.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/settings/settings_cubit.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/stores.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (reads google-services.json on Android / GoogleService-Info.plist on iOS)
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  await HiveService.init();

  await initCoreDependencies();
  await initFeatureDependencies();

  // Initialize FCM Push Notifications service
  try {
    final pushService = getIt<PushNotificationService>();
    if (pushService is FcmPushNotificationService) {
      await pushService.initialize();
    }
  } catch (e) {
    debugPrint('PushNotificationService initialize warning: $e');
  }

  final settings = AppSettingsCubit(getIt<PrefsStore>());
  getIt.registerLazySingleton<AppSettingsCubit>(() => settings);

  final router = AppRouter();
  getIt.registerLazySingleton<AppRouter>(() => router);

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      child: BlocProvider.value(
        value: settings,
        child: const ReuniteeApp(),
      ),
    ),
  );
}

class ReuniteeApp extends StatelessWidget {
  const ReuniteeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsState settings = context.watch<AppSettingsCubit>().state;
    final ThemeMode themeMode = switch (settings) {
      SettingsLoaded(:final themeMode) => themeMode,
    };
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: getIt<AppRouter>().config(),
    );
  }
}
