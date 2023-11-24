import 'package:get/get.dart';
import 'package:grab_customer_app/controllers/auth_controller.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/controllers/socket_controller.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/services/ride_api_service.dart';
import 'package:grab_customer_app/utils/constants/app_constants.dart';

enum RideState {
  isReadyForNextRide,
  isCompleted,
  isAccepted,
  isArrived,
}

class RideController extends GetxController {
  final RideService _rideService;
  final SocketController _socketController = Get.find();
  final AuthController _authController = Get.find();
  final MapController _mapController = Get.find();

  final rideState = RideState.isReadyForNextRide.obs;
  final acceptedRide = Ride().obs;
  final isLoading = true.obs;
  final rideHistoryList = <Ride>[].obs;

  RideController(this._rideService);

  Future<void> loadCurrentRide() async {
    var currentRides = await _getCurrentRides();
    acceptedRide.value = currentRides.isNotEmpty ? currentRides[0] : Ride();
    rideState.value = acceptedRide.value.status == ACCEPTED
        ? RideState.isAccepted
        : acceptedRide.value.status == IN_PROGRESS
            ? RideState.isArrived
            : RideState.isCompleted;
  }

  Future<void> createBookingNow(Ride ride) async {
    try {
      final result = await _rideService.createBookingNow(ride);

      if (result[STATUS] == true) {
        var ride = Ride.fromJson(result[DATA]);
        _socketController.book(ride);
        _mapController.rideRequest.value = ride;
        _mapController.bookingState.value = BookingState.isBooked;
      } else {
        // Handle failed ride creation
      }
    } catch (e) {
      // Handle errors
      print('Error creating booking now: $e');
    }
  }

  Future<void> cancelRide(String rideId) async {
    try {
      final result = await _rideService.cancelRide(rideId);

      if (result[STATUS] == true) {
        // Handle successful ride cancellation
      } else {
        // Handle failed ride cancellation
      }
    } catch (e) {
      // Handle errors
      print('Error canceling ride: $e');
    }
  }

  Future<List<Ride>> _getCurrentRides() async {
    try {
      final result = await _rideService.getCurrentRides(_authController.customerId.value);
      if (result[STATUS] == true) {
        final List<dynamic> rideData = result[DATA];

        // Map the list of dynamic data to a list of Ride objects
        final List<Ride> rides = rideData.map((data) => Ride.fromJson(data)).toList();

        // Return the list of Ride objects
        return rides;
      } else {
        // If status is not true, return an empty list
        return [];
      }
    } catch (e) {
      // Handle errors
      print('Error getting current rides: $e');
      return []; // Return an empty list in case of an error
    }
  }

  Future<void> getRides() async {
    try {
      isLoading.value = true;
      final result = await _rideService.getRides(_authController.customerId.value);
      if (result[STATUS] == true) {
        final List<dynamic> rideData = result[DATA];

        // Map the list of dynamic data to a list of Ride objects
        final List<Ride> rides = rideData.map((data) => Ride.fromJson(data)).toList();

        // Return the list of Ride objects
        isLoading.value = false;
        rideHistoryList.value = rides;
        return;
      } else {
        // If status is not true, return an empty list
        isLoading.value = false;
        return;
      }
    } catch (e) {
      // Handle errors
      print('Error getting rides: $e');
      isLoading.value = false;
      return;
    }
  }
}
