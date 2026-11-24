import 'dart:io';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'app_services.dart';
import 'core/appambit/analytics.dart';
import 'core/appambit/cloud_service.dart';
import 'core/appambit/diagnostics.dart';
import 'core/local_store.dart';

/// The version shown in Settings. It matches `version:` in pubspec.yaml; a release build can pass
/// its own with `--dart-define=APP_VERSION=1.2.3`.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await dotenv.load();

  // One AppAmbit app per platform (Foodmorrow App - iOS / - Android); both share FoodmorrowDb.
  final appKey = Platform.isIOS
      ? dotenv.env['APPAMBIT_IOS_APP_KEY']
      : dotenv.env['APPAMBIT_ANDROID_APP_KEY'];
  if (appKey != null && appKey.isNotEmpty) await AppAmbitSdk.start(appKey: appKey);

  final services = AppServices(
    cloud: AppAmbitCloudService(),
    analytics: const AppAmbitAnalytics(),
    diagnostics: const AppAmbitDiagnostics(),
    store: await PrefsStore.open(),
    platform: Platform.isIOS ? 'ios' : 'android',
    appVersion: appVersion,
  );
  // Creates the seller the first time this phone is seen and reads their settings. It never
  // throws: with no connection the app still opens, and each screen shows its own banner.
  await services.seller.hello();

  runApp(App(services: services));
}
