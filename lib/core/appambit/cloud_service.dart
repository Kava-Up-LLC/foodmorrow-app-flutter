import 'dart:convert';

import 'package:appambit_sdk_flutter/appambit_cloud_code.dart';
import 'package:flutter/foundation.dart';

import '../errors.dart';

/// AppAmbit Cloud Code: hello, profile, products, orders, home. The phone never touches the
/// database — this is the only way in or out.
abstract interface class CloudService {
  /// Calls [function] and gives back its answer, or throws [AppFailure].
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> body);
}

class AppAmbitCloudService implements CloudService {
  AppAmbitCloudService();

  /// Cloud Code calls go out one at a time. Several at once never come back — four parallel calls
  /// all hit the 20 s timeout on a real device (seen on the iPhone simulator, 2026-11-24).
  Future<void> _inFlight = Future<void>.value();

  static const _networkCodes = {
    CloudCodeErrorCode.networkUnavailable,
    CloudCodeErrorCode.timedOut,
    CloudCodeErrorCode.transport,
    CloudCodeErrorCode.http,
  };

  @override
  Future<Map<String, dynamic>> call(String function, Map<String, dynamic> body) {
    final mine = _inFlight.then((_) => _call(function, body));
    // The queue must keep moving even when a call fails.
    _inFlight = mine.then((_) {}, onError: (_) {});
    return mine;
  }

  Future<Map<String, dynamic>> _call(String function, Map<String, dynamic> body) async {
    final CloudCodeResponse response;
    try {
      response = await CloudCode.call(function, body: body, timeout: const Duration(seconds: 20)).future;
    } on CloudCodeError catch (e) {
      // Only in a debug build: the code behind a "No connection" is what you need to tell a
      // real outage from a timeout or a quota (seen while building: 429 and timedOut).
      if (kDebugMode) debugPrint('Cloud Code $function failed: ${e.code} — ${e.message}');
      throw AppFailure(
        _networkCodes.contains(e.code) ? FailureKind.noConnection : FailureKind.unexpected,
        e,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Cloud Code $function failed: ${e.runtimeType} — $e');
      // Anything we can't name is treated as "the cloud is not reachable": the screen then offers
      // Retry, which is the only useful thing the seller can do about it.
      throw AppFailure(FailureKind.noConnection, e);
    }

    final data = response.data is String ? jsonDecode(response.data! as String) : response.data;
    if (data is! Map) throw AppFailure(FailureKind.unexpected, 'Unexpected answer from $function');

    final map = Map<String, dynamic>.from(data);
    if (map['ok'] != true) throw AppFailure.fromCode(map['error'] as String?);
    return map;
  }
}
