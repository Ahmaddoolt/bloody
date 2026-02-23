// file: lib/core/utils/sorting_utils.dart
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
  }

  /// Smart Donor Sort Algorithm (For Receivers looking for Donors)
  /// Hierarchy:
  /// 1. Highest "Gamification Points"
  /// 2. Matches Requested Blood Type
  /// 3. Same City
  /// 4. Nearest Geolocation Distance
  static void sortDonors(
    List<Map<String, dynamic>> donors, {
    required String? receiverBloodType,
    required String? receiverCity,
    required double? receiverLat,
    required double? receiverLng,
  }) {
    donors.sort((a, b) {
      // 1. Highest Gamification Points
      final int pointsA = a['points'] ?? 0;
      final int pointsB = b['points'] ?? 0;
      if (pointsA != pointsB) {
        return pointsB.compareTo(pointsA); // Higher points first
      }

      // 2. Matches Requested Blood Type (Compatibility)
      if (receiverBloodType != null) {
        final aType = a['blood_type'];
        final bType = b['blood_type'];
        final compatibleList =
            BloodUtils.getCompatibleDonors(receiverBloodType);

        final aCompatible = compatibleList.contains(aType);
        final bCompatible = compatibleList.contains(bType);

        if (aCompatible != bCompatible) {
          return aCompatible ? -1 : 1;
        }
      }

      // 3. Same City
      if (receiverCity != null) {
        final aCity = a['city'];
        final bCity = b['city'];

        final bool aSame = (aCity != null && aCity == receiverCity);
        final bool bSame = (bCity != null && bCity == receiverCity);

        if (aSame != bSame) {
          return aSame ? -1 : 1;
        }
      }

      // 4. Nearest Geolocation Distance
      if (receiverLat != null && receiverLng != null) {
        final double? aLat = a['latitude'];
        final double? aLng = a['longitude'];
        final double? bLat = b['latitude'];
        final double? bLng = b['longitude'];

        if (aLat != null && aLng != null && bLat != null && bLng != null) {
          final distA = calculateDistance(receiverLat, receiverLng, aLat, aLng);
          final distB = calculateDistance(receiverLat, receiverLng, bLat, bLng);
          return distA.compareTo(distB);
        }
      }

      return 0;
    });
  }
}
