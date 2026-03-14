import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper class to create custom map markers
class MapMarkerHelper {
  static BitmapDescriptor? _hospitalMarker;
  static BitmapDescriptor? _donorMarker;
  static BitmapDescriptor? _receiverMarker;

  /// Get hospital marker (blue with hospital icon)
  static Future<BitmapDescriptor> getHospitalMarker() async {
    if (_hospitalMarker != null) return _hospitalMarker!;
    _hospitalMarker = await _createMarker(
      color: const Color(0xFF1976D2),
      icon: Icons.local_hospital,
    );
    return _hospitalMarker!;
  }

  /// Get donor marker (green with person icon)
  static Future<BitmapDescriptor> getDonorMarker() async {
    if (_donorMarker != null) return _donorMarker!;
    _donorMarker = await _createMarker(
      color: const Color(0xFF4CAF50),
      icon: Icons.person,
    );
    return _donorMarker!;
  }

  /// Get receiver marker (red with blood icon)
  static Future<BitmapDescriptor> getReceiverMarker() async {
    if (_receiverMarker != null) return _receiverMarker!;
    _receiverMarker = await _createMarker(
      color: const Color(0xFFE53935),
      icon: Icons.bloodtype,
    );
    return _receiverMarker!;
  }

  /// Create a custom marker with icon
  static Future<BitmapDescriptor> _createMarker({
    required Color color,
    required IconData icon,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 80.0;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(size / 2, size / 2 + 2),
      size / 2 - 4,
      shadowPaint,
    );

    // Draw white circle background
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      bgPaint,
    );

    // Draw colored circle
    final colorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 8,
      colorPaint,
    );

    // Draw icon using text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 36,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Clear cached markers (call when theme changes)
  static void clearCache() {
    _hospitalMarker = null;
    _donorMarker = null;
    _receiverMarker = null;
  }
}
