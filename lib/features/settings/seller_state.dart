import 'package:flutter/foundation.dart';

import 'settings_repository.dart';

/// Who the seller is, kept in one place because two screens need it: Home shows the business name
/// and Orders starts its week on the chosen day. `hello` fills it on every app start.
class SellerState extends ChangeNotifier {
  SellerState({required this.repository});

  final SettingsRepository repository;

  /// The defaults the cloud itself uses, so the app draws something sensible before `hello` lands.
  String businessName = 'My kitchen';
  String weekStart = 'mon';

  bool get startsOnSunday => weekStart == 'sun';

  /// False until `hello` has answered once. Settings uses it to know a retry is worth offering.
  bool loaded = false;

  /// Called on app start. Never throws: a phone with no connection still opens the app, and each
  /// screen shows its own No connection banner.
  ///
  /// It tries more than once. On a cold start the AppAmbit SDK may not have its consumer token yet
  /// and the first call comes back "Consumer token unavailable" (seen on a fresh Android emulator,
  /// 2026-11-24). Without the seller row every other call would then answer NOT_FOUND, so this one
  /// is worth waiting for — and `hello` is an upsert, so calling it again is harmless.
  Future<void> hello({int attempts = 3}) async {
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        _apply(await repository.hello());
        return;
      } catch (_) {
        if (attempt == attempts) return; // left at the defaults; the screens show their banner
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  /// Settings saved a change.
  void apply(SellerProfile profile) => _apply(profile);

  void _apply(SellerProfile profile) {
    businessName = profile.businessName;
    weekStart = profile.weekStart;
    loaded = true;
    notifyListeners();
  }
}
