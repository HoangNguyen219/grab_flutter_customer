import 'package:get/get.dart';
import 'package:grab_customer_app/controllers/auth_controller.dart';
import 'package:grab_customer_app/controllers/live_tracking_controller.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/models/driver.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/services/socket_service.dart';
import 'package:grab_customer_app/views/history/page/ride_history_page.dart';

class SocketController extends GetxController {
  final SocketService _socketService;
  final AuthController _authController = Get.find();
  final MapController _mapController = Get.find();
  final LiveTrackingController _liveTrackingController = Get.find();

  RxList<Driver> onlineDrivers = <Driver>[].obs;

  SocketController(this._socketService) {
    initSocket();
    addCustomer();
  }

  Future<void> initSocket() async {
    _socketService.connect(
      onOnlineDriver: _onOnlineDriver,
      onOfflineDriver: _onOfflineDriver,
      onAccept: _onAccept,
      onPick: _onPick,
      onComplete: _onComplete,
      onChangeLocationDriver: _onChangeLocationDriver,
      onConnect: () {
        addCustomer();
      },
    );
  }

  void _onOnlineDriver(Driver driver) {
    onlineDrivers.add(driver);
    _mapController.updateAvailableDrivers(onlineDrivers);
  }

  void _onOfflineDriver(driverId) {
    onlineDrivers.removeWhere((onlineDriver) => onlineDriver.driverId == driverId);
    _mapController.updateAvailableDrivers(onlineDrivers);
  }

  void _onAccept(Driver driver) {
    _mapController.bookingState.value = BookingState.isAccepted;
    _mapController.updateAcceptedDriver(driver);
  }

  void _onPick() {
    _mapController.bookingState.value = BookingState.isArrived;
    Get.snackbar("Driver arrived!", "Now you can track from history page!", snackPosition: SnackPosition.BOTTOM);
    Get.off(() => const RideHistoryPage());
  }

  void _onComplete() {
    _mapController.resetForNewTrip();
    Get.snackbar("Trip completed!", "Now you can book another trip!", snackPosition: SnackPosition.BOTTOM);
    Get.off(() => const RideHistoryPage());
  }

  void _onChangeLocationDriver(Driver driver) {
    if (_mapController.bookingState.value == BookingState.isAccepted) {
      _mapController.updateAcceptedDriver(driver);
    }
    if (_mapController.bookingState.value == BookingState.isArrived) {
      _liveTrackingController.getDirectionData(_mapController.rideRequest.value, driver);
    }
  }

  void closeSocket() {
    _socketService.disconnect();
  }

  void book(Ride ride) {
    _socketService.book(ride);
  }

  void removeCustomer() {
    _socketService.removeCustomer(_authController.customerId.value);
  }

  void addCustomer() {
    _socketService.addCustomer(_authController.customerId.value);
  }

  void cancelRide(Ride ride) {
    _socketService.cancel(ride.driverId, _authController.customerId.value);
    _mapController.resetForNewTrip();
    Get.snackbar("Trip Canceled", "The trip has been canceled.", snackPosition: SnackPosition.BOTTOM);
    Get.off(() => const RideHistoryPage());
  }
}
