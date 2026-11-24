import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// The only two things kept on the phone (spec §3): who this seller is, and whether Welcome is done.
/// Everything else lives in AppAmbit.
abstract interface class LocalStore {
  String get sellerId;
  bool get welcomeDone;
  Future<void> markWelcomeDone();
}

class PrefsStore implements LocalStore {
  PrefsStore._(this._prefs, this.sellerId);

  static Future<PrefsStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('seller_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('seller_id', id);
    }
    return PrefsStore._(prefs, id);
  }

  final SharedPreferences _prefs;

  @override
  final String sellerId;

  @override
  bool get welcomeDone => _prefs.getBool('welcome_done') ?? false;

  @override
  Future<void> markWelcomeDone() => _prefs.setBool('welcome_done', true);
}
