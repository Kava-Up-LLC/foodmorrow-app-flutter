import '../../core/appambit/cloud_service.dart';
import '../../core/dates.dart';
import 'data/home_data.dart';

/// Home, through the `home` Cloud Code function. The phone sends today and tomorrow; the cloud
/// never works them out (spec §2 rule 2).
abstract interface class HomeRepository {
  Future<HomeData> load();
}

class CloudHomeRepository implements HomeRepository {
  CloudHomeRepository({required this.cloud, required this.sellerId});

  final CloudService cloud;
  final String sellerId;

  @override
  Future<HomeData> load() async {
    final res = await cloud.call('home', {
      'seller_id': sellerId,
      'today': Dates.todayKey(),
      'tomorrow': Dates.tomorrowKey(),
    });
    return HomeData.fromJson(res);
  }
}
