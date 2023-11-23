import 'dart:async';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/utils/location_service.dart';

class HomeController extends GetxController {
  var currentLat = 10.762622.obs;
  var currentLng = 106.660172.obs;

  final Completer<GoogleMapController> googleMapController = Completer();

  void getCurrentLocation() async {
    final position = await LocationService.getLocation();

    if (position == null) {
      // Handle the case where the location permission is denied or null
      return;
    }

    try {
      final controller = await googleMapController.future;

      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18.0,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }
}
