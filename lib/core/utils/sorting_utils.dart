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
  /// 1. High Priority (is_priority = true)
  /// 2. Matches User's Blood Type (Compatible)
  /// 3. Same City
  /// 4. Nearest Geolocation Distance
  static void sortNeedyUsers(
    List<Map<String, dynamic>> users, {
    required String? donorBloodType,
    required String? donorCity,
    required double? donorLat,
    required double? donorLng,
  }) {
    users.sort((a, b) {
      // 1. High Priority
      final bool aPriority = a['is_priority'] ?? false;
      final bool bPriority = b['is_priority'] ?? false;
      if (aPriority != bPriority) {
        return aPriority ? -1 : 1; // Priority comes first
      }

      // 2. Matches User's Blood Type (Compatibility)
      if (donorBloodType != null) {
        final aType = a['blood_type'];
        final bType = b['blood_type'];
        final compatibleList =
            BloodUtils.getCompatibleReceivers(donorBloodType);

        final aCompatible = compatibleList.contains(aType);
        final bCompatible = compatibleList.contains(bType);

        if (aCompatible != bCompatible) {
          return aCompatible ? -1 : 1; // Compatible comes first
        }
      }

      // 3. Same City
      if (donorCity != null) {
        final aCity = a['city'];
        final bCity = b['city'];

        // Handle null cities gracefully
        final bool aSame = (aCity != null && aCity == donorCity);
        final bool bSame = (bCity != null && bCity == donorCity);

        if (aSame != bSame) {
          return aSame ? -1 : 1; // Same city comes first
        }
      }

      // 4. Nearest Geolocation Distance
      if (donorLat != null && donorLng != null) {
        final double? aLat = a['latitude'];
        final double? aLng = a['longitude'];
        final double? bLat = b['latitude'];
        final double? bLng = b['longitude'];

        if (aLat != null && aLng != null && bLat != null && bLng != null) {
          final distA = calculateDistance(donorLat, donorLng, aLat, aLng);
          final distB = calculateDistance(donorLat, donorLng, bLat, bLng);
          return distA.compareTo(distB); // Smaller distance first
        }
      }

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
      final isPriority = user['is_priority'] ?? false;

      // Calculate distance if coordinates available
      String distanceStr = 'N/A';
      if (donorLat != null && donorLng != null) {
        final double? userLat = user['latitude'];
        final double? userLng = user['longitude'];
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

  /// Smart Donor Sort Algorithm (For Receivers looking for Donors)
  /// Hierarchy:
  /// 1. Same City (most relevant — local help first)
  /// 2. Exact blood type match
  /// 3. Other compatible blood types
  /// 4. Nearest Geolocation Distance
  /// 5. Highest Points (tiebreaker)
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

      // 2. Exact blood type first, then other compatible types
      if (receiverBloodType != null) {
        final aType = a['blood_type'];
        final bType = b['blood_type'];
        final aExact = aType == receiverBloodType;
        final bExact = bType == receiverBloodType;
        if (aExact != bExact) return aExact ? -1 : 1;

        final compatibleList = BloodUtils.getCompatibleDonors(receiverBloodType);
        final aCompatible = compatibleList.contains(aType);
        final bCompatible = compatibleList.contains(bType);
        if (aCompatible != bCompatible) return aCompatible ? -1 : 1;
      }

      // 3. Nearest Geolocation Distance
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

      // 4. Highest Gamification Points (tiebreaker)
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
