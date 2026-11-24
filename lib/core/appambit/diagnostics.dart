import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

/// Crash reports are on by default with the SDK. This is only the test crash for the video:
/// long-press the "Orders" title (spec §10). Nothing in the UI mentions it.
abstract interface class Diagnostics {
  void testCrash();
}

class AppAmbitDiagnostics implements Diagnostics {
  const AppAmbitDiagnostics();

  @override
  void testCrash() => AppAmbitSdk.generateTestCrash();
}
