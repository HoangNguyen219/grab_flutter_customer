import 'dart:async';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/utils/location_service.dart';

class HomeController extends GetxController {
  final currentLat = 0.0.obs;
  final currentLng = 0.0.obs;

  final Completer<GoogleMapController> googleMapController = Completer();

  @override
  void onInit() {
    super.onInit();
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    final position = await LocationService.getLocation();

    if (position == null) {
      // Handle the case where the location permission is denied or null
      return;
    }
    currentLat.value = position.latitude;
    currentLng.value = position.longitude;
  }

  void getCurrentLocation() async {
    try {
      final controller = await googleMapController.future;

      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentLat.value, currentLng.value),
            zoom: 18.0,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }
}
