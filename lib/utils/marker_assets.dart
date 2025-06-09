// TODO Implement this library.
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class MarkerAssets {
  static BitmapDescriptor? locationIcon;

  static Future<void> preloadIcons() async {
    if (locationIcon == null) {
      locationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/icons/location_marker.png',
      );
    }
  }
}