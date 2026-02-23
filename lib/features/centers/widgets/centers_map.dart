// file: lib/features/centers/widgets/centers_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CentersMap extends StatelessWidget {
  final Set<Marker> markers;
  static const LatLng _defaultLocation = LatLng(33.5138, 36.2765);

  const CentersMap({super.key, required this.markers});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _defaultLocation,
        zoom: 11,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
