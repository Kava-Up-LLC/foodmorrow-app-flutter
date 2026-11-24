import 'package:flutter/foundation.dart';

import 'errors.dart';

/// What every screen that reads from the cloud has in common: it is loading, it failed, or it has
/// something to show. Controllers extend this and fill in [fetch]; views use `ListenableBuilder`.
///
/// Online only (spec §7.5): a failure is shown as the alert banner with Retry over skeletons, and
/// nothing is cached.
abstract class LoadableController extends ChangeNotifier {
  bool _loading = true;
  AppFailure? _failure;
  bool _disposed = false;

  bool get loading => _loading;
  AppFailure? get failure => _failure;

  /// True while a write (save, delete, picked up) is in flight.
  bool _busy = false;
  bool get busy => _busy;

  /// Reads everything this screen needs. Throws [AppFailure] when it can't.
  Future<void> fetch();

  /// Loads, or loads again after Retry.
  Future<void> load() async {
    _loading = true;
    _failure = null;
    _safeNotify();
    await _guard(fetch);
    _loading = false;
    _safeNotify();
  }

  /// Runs a write with the busy flag set, and keeps any failure for the banner.
  /// Returns true when it went through.
  Future<bool> runWrite(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _failure = null;
    _safeNotify();
    final ok = await _guard(action);
    _busy = false;
    _safeNotify();
    return ok;
  }

  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on AppFailure catch (e) {
      _failure = e;
    } catch (e) {
      _failure = AppFailure(FailureKind.unexpected, e);
    }
    return false;
  }

  /// Clears the banner, for instance after the seller has read a "check what you typed".
  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// For controllers that change their own fields and need the view to catch up.
  @protected
  void refresh() => _safeNotify();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
