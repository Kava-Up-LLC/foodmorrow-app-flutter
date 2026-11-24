import '../../core/appambit/cloud_service.dart';

/// Who the seller is: the business name shown on Home and the day their week starts on.
class SellerProfile {
  const SellerProfile({required this.businessName, required this.weekStart});

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
        businessName: json['business_name'] as String,
        weekStart: json['week_start'] as String,
      );

  final String businessName;

  /// 'mon' or 'sun'.
  final String weekStart;

  bool get startsOnSunday => weekStart == 'sun';
}

/// `hello` on every app start, `profile` for Settings.
abstract interface class SettingsRepository {
  /// Creates the seller the first time this phone is seen, and reads their settings.
  Future<SellerProfile> hello();

  Future<SellerProfile> save({String? businessName, String? weekStart});
}

class CloudSettingsRepository implements SettingsRepository {
  CloudSettingsRepository({required this.cloud, required this.sellerId, required this.platform});

  final CloudService cloud;
  final String sellerId;

  /// 'ios' or 'android'.
  final String platform;

  @override
  Future<SellerProfile> hello() async {
    final res = await cloud.call('hello', {'seller_id': sellerId, 'platform': platform});
    return SellerProfile.fromJson(res);
  }

  @override
  Future<SellerProfile> save({String? businessName, String? weekStart}) async {
    final res = await cloud.call('profile', {
      'seller_id': sellerId,
      'business_name': ?businessName,
      'week_start': ?weekStart,
    });
    return SellerProfile.fromJson(res);
  }
}
