import '../entities/priority_request_entity.dart';

abstract class PriorityRepository {
  Future<List<PriorityRequestEntity>> fetchPendingRequests();
  Future<void> updatePriorityStatus(String userId, String status);
}
