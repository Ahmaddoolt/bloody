import '../entities/admin_home_entity.dart';

abstract class AdminHomeRepository {
  Future<List<CenterEntity>> fetchCenters({
    required int limit,
    required int offset,
    String? searchQuery,
    String? city,
  });

  Future<Map<String, int>> fetchCenterStockTotals();

  Future<int> fetchPendingPriorityCount();

  Future<void> sendNotificationToDonors({
    required String city,
    String? bloodType,
    String? title,
    String? body,
  });
}
