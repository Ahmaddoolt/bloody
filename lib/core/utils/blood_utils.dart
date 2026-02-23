// file: lib/core/utils/blood_utils.dart

class BloodUtils {
  /// Returns a list of blood types that a [donorType] can donate to.
  /// Example: O- returns all types. A+ returns [A+, AB+].
  static List<String> getCompatibleReceivers(String donorType) {
    switch (donorType) {
      case 'O-':
        return ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']; // Universal
      case 'O+':
        return ['O+', 'A+', 'B+', 'AB+'];
      case 'A-':
        return ['A+', 'A-', 'AB+', 'AB-'];
      case 'A+':
        return ['A+', 'AB+'];
      case 'B-':
        return ['B+', 'B-', 'AB+', 'AB-'];
      case 'B+':
        return ['B+', 'AB+'];
      case 'AB-':
        return ['AB+', 'AB-'];
      case 'AB+':
        return ['AB+'];
      default:
        return [];
    }
  }

  /// Returns a list of blood types that a [receiverType] can receive from.
  /// Example: AB+ returns all types. O- returns only [O-].
  static List<String> getCompatibleDonors(String receiverType) {
    switch (receiverType) {
      case 'AB+':
        return [
          'A+',
          'A-',
          'B+',
          'B-',
          'AB+',
          'AB-',
          'O+',
          'O-'
        ]; // Universal Receiver
      case 'AB-':
        return ['AB-', 'A-', 'B-', 'O-'];
      case 'A+':
        return ['A+', 'A-', 'O+', 'O-'];
      case 'A-':
        return ['A-', 'O-'];
      case 'B+':
        return ['B+', 'B-', 'O+', 'O-'];
      case 'B-':
        return ['B-', 'O-'];
      case 'O+':
        return ['O+', 'O-'];
      case 'O-':
        return ['O-'];
      default:
        return [];
    }
  }

  /// Calculates age from a date string (YYYY-MM-DD)
  static int calculateAge(String? birthDateString) {
    if (birthDateString == null || birthDateString.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(birthDateString);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }
}
