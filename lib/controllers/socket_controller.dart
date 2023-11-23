import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:grab_customer_app/controllers/auth_controller.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/services/socket_service.dart';

class SocketController extends GetxController {
  final SocketService _socketService;
  final AuthController _authController = Get.find();

  RxList<Ride> rideRequests = <Ride>[].obs;

  SocketController(this._socketService) {
    initSocket();
  }

  void initSocket() {
    _socketService.connect(
      onOnlineCustomer: (Ride ride) {
        rideRequests.add(ride);
      },
      onCancel: (customerId) {
        rideRequests.removeWhere((rideRequest) => rideRequest.customerId == customerId);
      },
      onOfflineCustomer: (customerId) {
        rideRequests.removeWhere((rideRequest) => rideRequest.customerId == customerId);
      },
    );
  }

  void closeSocket() {
    _socketService.disconnect();
  }

  void addDriver(int driverId, Position location) {
    _socketService.addDriver(driverId, location);
  }

  void removeDriver(int driverId) {
    _socketService.removeDriver(driverId);
  }

  void acceptRide(Ride ride) {
    _socketService.acceptRide(_authController.customerId.value, ride.customerId!);
    rideRequests.removeWhere((rideRequest) => rideRequest.customerId == ride.customerId);
  }

  void pickRide(Ride ride) {
    _socketService.pickRide(_authController.customerId.value, ride.customerId!);
  }

  void completeRide(Ride ride) {
    _socketService.completeRide(_authController.customerId.value, ride.customerId!);
  }
}
