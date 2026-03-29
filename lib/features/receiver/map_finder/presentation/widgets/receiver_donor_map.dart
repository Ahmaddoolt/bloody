import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/receiver_map_provider.dart';
import 'receiver_home_states.dart';

const _syrianCityCoordinates = <String, LatLng>{
  'Damascus': LatLng(33.5138, 36.2765),
  'Aleppo': LatLng(36.2021, 37.1343),
  'Homs': LatLng(34.7324, 36.7137),
  'Hama': LatLng(35.1318, 36.7551),
  'Latakia': LatLng(35.5317, 35.7917),
  'Tartus': LatLng(34.8959, 35.8866),
  'Idlib': LatLng(35.9306, 36.6339),
  'Daraa': LatLng(32.6189, 36.1021),
  'As-Suwayda': LatLng(32.7086, 36.5661),
  'Quneitra': LatLng(33.1261, 35.8243),
  'Deir ez-Zor': LatLng(35.3354, 40.1407),
  'Al-Hasakah': LatLng(36.4844, 40.7489),
  'Raqqa': LatLng(35.9500, 39.0100),
  'Rif Dimashq': LatLng(33.5500, 36.4500),
};

class ReceiverDonorMap extends StatelessWidget {
  final ReceiverMapState state;
  final BitmapDescriptor? donorMarkerIcon;
  final double horizontalPadding;
  final VoidCallback onRetryLocation;
  final ValueChanged<Map<String, dynamic>> onOpenDonor;

  const ReceiverDonorMap({
    super.key,
    required this.state,
    required this.donorMarkerIcon,
    required this.horizontalPadding,
    required this.onRetryLocation,
    required this.onOpenDonor,
  });

  @override
  Widget build(BuildContext context) {
    // Show error state only when both GPS and city fallback are unavailable
    if (state.currentPosition == null && state.fallbackLatLng == null) {
      final statusMessage =
          state.statusKey.isEmpty ? '' : state.statusKey.tr();

      return ReceiverLocationState(
        statusMessage: statusMessage,
        horizontalPadding: horizontalPadding,
        onRetry: onRetryLocation,
      );
    }

    final center = state.currentPosition != null
        ? LatLng(
            state.currentPosition!.latitude,
            state.currentPosition!.longitude,
          )
        : state.fallbackLatLng!;

    final markers = <Marker>{};
    for (final donor in state.donors) {
      final latitude = donor['latitude'];
      final longitude = donor['longitude'];
      final city = donor['city'] as String?;

      LatLng? position;
      if (latitude != null && longitude != null) {
        position = LatLng((latitude as num).toDouble(), (longitude as num).toDouble());
      } else if (city != null) {
        position = _syrianCityCoordinates[city];
      }
      if (position == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(donor['id'] as String),
          position: position,
          icon: donorMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '${'donor'.tr()}: ${donor['blood_type']}',
            snippet: 'tap_to_see_details'.tr(),
            onTap: () => onOpenDonor(donor),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 14,
          ),
          myLocationEnabled: state.currentPosition != null,
          myLocationButtonEnabled: state.currentPosition != null,
          markers: markers,
        ),
      ),
    );
  }
}
