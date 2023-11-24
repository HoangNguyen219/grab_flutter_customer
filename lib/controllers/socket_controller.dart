import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:grab_customer_app/controllers/auth_controller.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/models/driver.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/services/socket_service.dart';
import 'package:grab_customer_app/utils/location_service.dart';

class SocketController extends GetxController {
  final SocketService _socketService;
  final AuthController _authController = Get.find();
  final MapController _mapController = Get.find();

  RxList<Driver> onlineDrivers = <Driver>[].obs;

  SocketController(this._socketService) {
    initSocket();
  }

  Future<void> initSocket() async {
    _socketService.connect(
      onOnlineDriver: (Driver driver) {
        onlineDrivers.add(driver);
        _mapController.updateAvailableDrivers(onlineDrivers);
      },
      onOfflineDriver: (driverId) {
        onlineDrivers.removeWhere((onlineDriver) => onlineDriver.driverId == driverId);
      },
    );
    final location = await LocationService.getLocation();
    if (location == null) {
      return;
    }
    addCustomer(_authController.customerId.value, location);
  }

  void closeSocket() {
    _socketService.disconnect();
  }

  void book(Ride ride) {
    _socketService.book(ride);
  }

  void removeCustomer(int customerId) {
    _socketService.removeCustomer(customerId);
  }

  void addCustomer(int customerId, Position location) {
    _socketService.addCustomer(customerId, location);
  }

  void cancelRide(Ride ride) {
    _socketService.cancel(ride.driverId!, _authController.customerId.value);
  }
}
