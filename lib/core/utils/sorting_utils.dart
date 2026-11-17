// file: lib/core/utils/sorting_utils.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'blood_utils.dart';

class SortingUtils {
  /// Calculates distance between two coordinates in kilometers.
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000.0;
  }

  /// Smart Needy Sort Algorithm (For Donors looking for Receivers)
  /// Hierarchy:
  /// 1. Has situation/description (blood_request_reason not empty)
  /// 2. High priority (priority_status = high, or legacy is_priority = true)
  /// 3. Nearest geolocation distance
  /// 4. Exact blood type match as a final tiebreaker
  static void sortNeedyUsers(
    List<Map<String, dynamic>> users, {
    required String? donorBloodType,
    required String? donorCity,
    required double? donorLat,
    required double? donorLng,
  }) {
    users.sort((a, b) {
      final aHasDesc = _hasBloodRequestReason(a);
      final bHasDesc = _hasBloodRequestReason(b);
      if (aHasDesc != bHasDesc) return aHasDesc ? -1 : 1;

      final aPriority = _isHighPriorityReceiver(a);
      final bPriority = _isHighPriorityReceiver(b);
      if (aPriority != bPriority) return aPriority ? -1 : 1;

      final distanceComparison = _compareDistance(
        a,
        b,
        originLat: donorLat,
        originLng: donorLng,
      );
      if (distanceComparison != 0) return distanceComparison;

      if (donorBloodType != null) {
        final aExact = a['blood_type'] == donorBloodType;
        final bExact = b['blood_type'] == donorBloodType;
        if (aExact != bExact) return aExact ? -1 : 1;
      }

      final aName = a['username']?.toString() ?? '';
      final bName = b['username']?.toString() ?? '';
      if (aName != bName) return aName.compareTo(bName);

      return 0;
    });

    // Print sorted list with priority info
    _printSortedReceivers(
      users,
      donorBloodType: donorBloodType,
      donorCity: donorCity,
      donorLat: donorLat,
      donorLng: donorLng,
    );
  }

  /// Prints sorted receivers with priority information to debug console
  static void _printSortedReceivers(
    List<Map<String, dynamic>> users, {
    String? donorBloodType,
    String? donorCity,
    double? donorLat,
    double? donorLng,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln(
        '╔═══════════════════════════════════════════════════════════════');
    buffer.writeln('║  📋 SORTED RECEIVERS LIST (By Priority)');
    buffer.writeln(
        '╠═══════════════════════════════════════════════════════════════');
    buffer.writeln('║  Total: ${users.length} receivers');
    buffer.writeln(
        '║  Donor Blood: ${donorBloodType ?? 'N/A'} | City: ${donorCity ?? 'N/A'}');
    buffer.writeln(
        '╠═══════════════════════════════════════════════════════════════');

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final name = user['username'] ?? user['email'] ?? 'Unknown';
      final bloodType = user['blood_type'] ?? '?';
      final city = user['city'] ?? 'N/A';
      final isPriority = _isHighPriorityReceiver(user);
      final hasSituation = _hasBloodRequestReason(user);

      // Calculate distance if coordinates available
      String distanceStr = 'N/A';
      if (donorLat != null && donorLng != null) {
        final userLat = (user['latitude'] as num?)?.toDouble();
        final userLng = (user['longitude'] as num?)?.toDouble();
        if (userLat != null && userLng != null) {
          final dist = calculateDistance(donorLat, donorLng, userLat, userLng);
          distanceStr = '${dist.toStringAsFixed(1)} km';
        }
      }

      // Check compatibility
      String compatStatus = '❌';
      if (donorBloodType != null) {
        final compatibleList =
            BloodUtils.getCompatibleReceivers(donorBloodType);
        if (compatibleList.contains(bloodType)) {
          compatStatus = '✅';
        }
      }

      // Check same city
      String cityStatus = '❌';
      if (donorCity != null && city == donorCity) {
        cityStatus = '✅';
      }

      // Priority indicator
      String priorityBadge = isPriority ? '⭐ PRIORITY' : '  ';
      if (hasSituation) priorityBadge = '$priorityBadge SITUATION';

      buffer.writeln('║  ${(i + 1).toString().padLeft(2)}. $priorityBadge');
      buffer.writeln('║      Name: $name');
      buffer.writeln(
          '║      Blood: $bloodType $compatStatus | City: $city $cityStatus');
      buffer.writeln('║      Distance: $distanceStr');
      buffer.writeln(
          '╟───────────────────────────────────────────────────────────────');
    }

    buffer.writeln(
        '╚═══════════════════════════════════════════════════════════════');
    debugPrint(buffer.toString());
  }

  static bool _hasBloodRequestReason(Map<String, dynamic> user) {
    return user['blood_request_reason']?.toString().trim().isNotEmpty == true;
  }

  static bool _isHighPriorityReceiver(Map<String, dynamic> user) {
    return user['priority_status'] == 'high' || user['is_priority'] == true;
  }

  static int _compareDistance(
    Map<String, dynamic> a,
    Map<String, dynamic> b, {
    required double? originLat,
    required double? originLng,
  }) {
    if (originLat == null || originLng == null) return 0;

    final aDistance = _distanceFrom(originLat, originLng, a);
    final bDistance = _distanceFrom(originLat, originLng, b);

    if (aDistance == null && bDistance == null) return 0;
    if (aDistance == null) return 1;
    if (bDistance == null) return -1;

    return aDistance.compareTo(bDistance);
  }

  static double? _distanceFrom(
    double originLat,
    double originLng,
    Map<String, dynamic> user,
  ) {
    final lat = (user['latitude'] as num?)?.toDouble();
    final lng = (user['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return calculateDistance(originLat, originLng, lat, lng);
  }

  /// Smart Donor Sort Algorithm (For Receivers looking for Donors)
  /// Hierarchy:
  /// 1. Same City (most relevant — local help first)
  /// 2. Verified account
  /// 3. Exact blood type match
  /// 4. Other compatible blood types
  /// 5. Nearest Geolocation Distance
  /// 6. Highest Points (tiebreaker)
  static void sortDonors(
    List<Map<String, dynamic>> donors, {
    required String? receiverBloodType,
    required String? receiverCity,
    required double? receiverLat,
    required double? receiverLng,
  }) {
    donors.sort((a, b) {
      // 1. Same City
      if (receiverCity != null) {
        final bool aSame = a['city'] != null && a['city'] == receiverCity;
        final bool bSame = b['city'] != null && b['city'] == receiverCity;
        if (aSame != bSame) return aSame ? -1 : 1;
      }

      // 2. Verified donors are more trustworthy inside the local pool.
      final bool aVerified = a['verification_status'] == 'verified';
      final bool bVerified = b['verification_status'] == 'verified';
      if (aVerified != bVerified) return aVerified ? -1 : 1;

      // 3. Exact blood type first, then other compatible types
      if (receiverBloodType != null) {
        final aType = a['blood_type'];
        final bType = b['blood_type'];
        final aExact = aType == receiverBloodType;
        final bExact = bType == receiverBloodType;
        if (aExact != bExact) return aExact ? -1 : 1;

        final compatibleList =
            BloodUtils.getCompatibleDonors(receiverBloodType);
        final aCompatible = compatibleList.contains(aType);
        final bCompatible = compatibleList.contains(bType);
        if (aCompatible != bCompatible) return aCompatible ? -1 : 1;
      }

      // 4. Nearest Geolocation Distance
      if (receiverLat != null && receiverLng != null) {
        final double? aLat = (a['latitude'] as num?)?.toDouble();
        final double? aLng = (a['longitude'] as num?)?.toDouble();
        final double? bLat = (b['latitude'] as num?)?.toDouble();
        final double? bLng = (b['longitude'] as num?)?.toDouble();

        if (aLat != null && aLng != null && bLat != null && bLng != null) {
          final distA = calculateDistance(receiverLat, receiverLng, aLat, aLng);
          final distB = calculateDistance(receiverLat, receiverLng, bLat, bLng);
          if (distA != distB) return distA.compareTo(distB);
        }
      }

      // 5. Highest Gamification Points (tiebreaker)
      final int pointsA = (a['points'] as num?)?.toInt() ?? 0;
      final int pointsB = (b['points'] as num?)?.toInt() ?? 0;
      return pointsB.compareTo(pointsA);
    });
  }

  /// Prints sorted centers with stock information to debug console
  static void printSortedCenters(
    List<Map<String, dynamic>> centers,
    Map<String, int> stockTotals,
  ) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln(
        '╔═══════════════════════════════════════════════════════════════');
    buffer.writeln('║  🏥 SORTED CENTERS LIST (By Stock - Lowest First)');
    buffer.writeln(
        '╠═══════════════════════════════════════════════════════════════');
    buffer.writeln('║  Total: ${centers.length} centers');
    buffer.writeln(
        '╠═══════════════════════════════════════════════════════════════');

    for (int i = 0; i < centers.length; i++) {
      final center = centers[i];
      final name = center['name'] ?? 'Unknown';
      final city = center['city'] ?? 'N/A';
      final id = center['id']?.toString() ?? '';
      final stock = stockTotals[id] ?? 0;

      buffer.writeln('║  ${(i + 1).toString().padLeft(2)}. $name');
      buffer.writeln('║      City: $city | Stock: $stock units');
      buffer.writeln(
          '╟───────────────────────────────────────────────────────────────');
    }

    buffer.writeln(
        '╚═══════════════════════════════════════════════════════════════');
    debugPrint(buffer.toString());
  }
}
