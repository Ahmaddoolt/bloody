abstract class AppCities {
  AppCities._();

  static const List<String> syrianCities = [
    'Damascus',
    'Aleppo',
    'Homs',
    'Hama',
    'Latakia',
    'Tartus',
    'Idlib',
    'Daraa',
    'As-Suwayda',
    'Quneitra',
    'Deir ez-Zor',
    'Al-Hasakah',
    'Raqqa',
    'Rif Dimashq',
  ];

  /// Center coordinates for each city — used to pre-center the location picker
  /// and as a fallback when GPS is unavailable.
  static const Map<String, List<double>> cityCoordinates = {
    'Damascus':    [33.5138, 36.2765],
    'Aleppo':      [36.2021, 37.1343],
    'Homs':        [34.7324, 36.7137],
    'Hama':        [35.1318, 36.7551],
    'Latakia':     [35.5317, 35.7917],
    'Tartus':      [34.8959, 35.8866],
    'Idlib':       [35.9306, 36.6339],
    'Daraa':       [32.6189, 36.1021],
    'As-Suwayda':  [32.7086, 36.5661],
    'Quneitra':    [33.1261, 35.8243],
    'Deir ez-Zor': [35.3354, 40.1407],
    'Al-Hasakah':  [36.4844, 40.7489],
    'Raqqa':       [35.9500, 39.0100],
    'Rif Dimashq': [33.5500, 36.4500],
  };

  static const List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
}
