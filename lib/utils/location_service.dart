import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationService {
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
}
