// Fires the test crash of spec §10 the way the video does it: a long press on the "Orders"
// title. The crash then shows up in that app's Diagnostics in AppAmbit.
//
//   flutter test integration_test/test_crash_test.dart -d <device>
//
// The app is meant to go down, so this file is on its own and is not part of `flutter test`.
import 'dart:io';

import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodmorrow_app/app.dart';
import 'package:foodmorrow_app/app_services.dart';
import 'package:foodmorrow_app/core/appambit/analytics.dart';
import 'package:foodmorrow_app/core/appambit/cloud_service.dart';
import 'package:foodmorrow_app/core/appambit/diagnostics.dart';
import 'package:foodmorrow_app/core/local_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('long-pressing the Orders title raises the test crash', (tester) async {
    await dotenv.load();
    final appKey = Platform.isIOS
        ? dotenv.env['APPAMBIT_IOS_APP_KEY']
        : dotenv.env['APPAMBIT_ANDROID_APP_KEY'];
    await AppAmbitSdk.start(appKey: appKey!);

    (await SharedPreferences.getInstance()).setBool('welcome_done', true);
    final services = AppServices(
      cloud: AppAmbitCloudService(),
      analytics: const AppAmbitAnalytics(),
      diagnostics: const AppAmbitDiagnostics(),
      store: await PrefsStore.open(),
      platform: Platform.isIOS ? 'ios' : 'android',
      appVersion: '1.0.0',
    );
    await services.seller.hello();

    await tester.pumpWidget(App(services: services));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    await tester.tap(find.bySemanticsLabel('Orders'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    debugPrint('LONG PRESS on the Orders title');
    await tester.longPress(find.text('Orders').first);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    debugPrint('TEST CRASH RAISED');
  });
}
