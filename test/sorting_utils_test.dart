import 'package:bloody/core/utils/sorting_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('needy receivers with situation and high priority rank first', () {
    final receivers = <Map<String, dynamic>>[
      {
        'id': 'priority_only',
        'blood_type': 'A+',
        'priority_status': 'high',
        'latitude': 0.01,
        'longitude': 0.0,
      },
      {
        'id': 'situation_only',
        'blood_type': 'A+',
        'priority_status': 'none',
        'blood_request_reason': 'Needs surgery',
        'latitude': 0.01,
        'longitude': 0.0,
      },
      {
        'id': 'situation_and_priority',
        'blood_type': 'A+',
        'priority_status': 'high',
        'blood_request_reason': 'Emergency',
        'latitude': 0.02,
        'longitude': 0.0,
      },
    ];

    SortingUtils.sortNeedyUsers(
      receivers,
      donorBloodType: 'A+',
      donorCity: 'Damascus',
      donorLat: 0.0,
      donorLng: 0.0,
    );

    expect(receivers.map((receiver) => receiver['id']), [
      'situation_and_priority',
      'situation_only',
      'priority_only',
    ]);
  });

  test('needy receiver distance sorts within same situation and priority', () {
    final receivers = <Map<String, dynamic>>[
      {
        'id': 'far',
        'blood_type': 'A+',
        'priority_status': 'high',
        'blood_request_reason': 'Emergency',
        'latitude': 0.03,
        'longitude': 0.0,
      },
      {
        'id': 'near',
        'blood_type': 'A+',
        'priority_status': 'high',
        'blood_request_reason': 'Emergency',
        'latitude': 0.01,
        'longitude': 0.0,
      },
    ];

    SortingUtils.sortNeedyUsers(
      receivers,
      donorBloodType: 'A+',
      donorCity: 'Damascus',
      donorLat: 0.0,
      donorLng: 0.0,
    );

    expect(receivers.first['id'], 'near');
  });

  test('legacy is_priority still ranks needy receiver as high priority', () {
    final receivers = <Map<String, dynamic>>[
      {
        'id': 'normal',
        'blood_type': 'A+',
        'blood_request_reason': 'Emergency',
      },
      {
        'id': 'legacy_priority',
        'blood_type': 'A+',
        'blood_request_reason': 'Emergency',
        'is_priority': true,
      },
    ];

    SortingUtils.sortNeedyUsers(
      receivers,
      donorBloodType: 'A+',
      donorCity: null,
      donorLat: null,
      donorLng: null,
    );

    expect(receivers.first['id'], 'legacy_priority');
  });

  test('verified donors rank before unverified donors in the same city', () {
    final donors = <Map<String, dynamic>>[
      {
        'id': 'unverified',
        'city': 'Damascus',
        'blood_type': 'A+',
        'verification_status': 'unverified',
        'points': 80,
      },
      {
        'id': 'verified',
        'city': 'Damascus',
        'blood_type': 'A+',
        'verification_status': 'verified',
        'points': 5,
      },
    ];

    SortingUtils.sortDonors(
      donors,
      receiverBloodType: 'A+',
      receiverCity: 'Damascus',
      receiverLat: null,
      receiverLng: null,
    );

    expect(donors.first['id'], 'verified');
  });

  test('same-city donors still rank before verified donors in another city',
      () {
    final donors = <Map<String, dynamic>>[
      {
        'id': 'remote_verified',
        'city': 'Aleppo',
        'blood_type': 'A+',
        'verification_status': 'verified',
        'points': 50,
      },
      {
        'id': 'local_unverified',
        'city': 'Damascus',
        'blood_type': 'A+',
        'verification_status': 'unverified',
        'points': 5,
      },
    ];

    SortingUtils.sortDonors(
      donors,
      receiverBloodType: 'A+',
      receiverCity: 'Damascus',
      receiverLat: null,
      receiverLng: null,
    );

    expect(donors.first['id'], 'local_unverified');
  });
}
