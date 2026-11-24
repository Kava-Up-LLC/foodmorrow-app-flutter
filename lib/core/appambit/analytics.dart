import 'package:appambit_sdk_flutter/appambit_sdk_flutter.dart';

/// The usage events of spec §8, in AppAmbit Analytics. No personal data: never a customer name.
abstract interface class Analytics {
  void track(String event, [Map<String, String> properties]);
}

class AppAmbitAnalytics implements Analytics {
  const AppAmbitAnalytics();

  @override
  void track(String event, [Map<String, String> properties = const {}]) {
    AppAmbitSdk.trackEvent(event, properties).catchError((_) {});
  }
}

/// The event names, so a typo can't quietly lose one.
abstract final class Events {
  static const welcomeDone = 'welcome_done';
  static const productAdded = 'product_added';
  static const orderSaved = 'order_saved';
  static const orderEdited = 'order_edited';
  static const orderPickedUp = 'order_picked_up';
  static const orderDeleted = 'order_deleted';
  static const tomorrowListViewed = 'tomorrow_list_viewed';
  static const searchUsed = 'search_used';
}
