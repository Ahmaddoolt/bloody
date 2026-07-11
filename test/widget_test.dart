import 'package:bloody/core/constants/app_constants.dart';
import 'package:bloody/core/constants/app_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('support email is configured', () {
    expect(AppSupport.email, 'support@bloody.app');
  });

  test('blood type list contains the standard eight groups', () {
    expect(
      AppCities.bloodTypes,
      containsAll(<String>['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']),
    );
  });
}
