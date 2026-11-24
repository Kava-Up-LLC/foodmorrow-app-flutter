import '../../core/loadable.dart';
import 'seller_state.dart';
import 'settings_repository.dart';

/// Settings: the business name and the day the week starts on.
class SettingsController extends LoadableController {
  SettingsController({required this.repository, required this.seller});

  static const maxBusinessName = 40;

  final SettingsRepository repository;
  final SellerState seller;

  String get businessName => seller.businessName;
  String get weekStart => seller.weekStart;
  bool get startsOnSunday => seller.startsOnSunday;

  @override
  Future<void> fetch() async {
    seller.apply(await repository.hello());
  }

  Future<bool> saveBusinessName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxBusinessName) return Future.value(false);
    return runWrite(() async {
      seller.apply(await repository.save(businessName: trimmed));
    });
  }

  Future<bool> saveWeekStart(String value) => runWrite(() async {
        seller.apply(await repository.save(weekStart: value));
      });
}
