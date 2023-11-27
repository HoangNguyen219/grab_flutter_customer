import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:grab_customer_app/models/ride.dart';

class LocationService {
  static late Position _lastKnownPosition;
  static const double _distanceThreshold = 100;

  static Future<Position?> getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permissions are denied", Colors.redAccent);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Location permissions are permanently denied, please enable it from app settings", Colors.redAccent);
      return null;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        print(e);
        return null;
      }
    }
    return null;
  }

  static void _showSnackBar(String message, Color backgroundColor) {
    Get.snackbar(
      "Alert",
      message,
      backgroundColor: backgroundColor,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static Future<void> trackCurrentLocation(void Function(Ride ride, Position location)? changeLocation, Ride ride) async {
    _lastKnownPosition = await Geolocator.getCurrentPosition();
    changeLocation?.call(ride, _lastKnownPosition);
    // Listen for location changes
    Geolocator.getPositionStream().listen((Position position) {
      double distanceInMeters = Geolocator.distanceBetween(
        _lastKnownPosition.latitude,
        _lastKnownPosition.longitude,
        position.latitude,
        position.longitude,
      );
      if (distanceInMeters >= _distanceThreshold) {
        // Send updated position to the server
        print('Position has changed significantly: $position');
        _lastKnownPosition = position;
        changeLocation?.call(ride, position);
      }
    });
  }

}
