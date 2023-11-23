import 'package:get/get.dart';
import 'package:grab_customer_app/controllers/auth_controller.dart';
import 'package:grab_customer_app/controllers/socket_controller.dart';
import 'package:grab_customer_app/utils/constants/app_constants.dart';
import 'package:grab_customer_app/utils/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CustomerStatus { online, offline }

class CustomerController extends GetxController {
  final Rx<CustomerStatus> customerStatus = CustomerStatus.offline.obs;
  final SocketController _socketController = Get.find();
  final AuthController _authController = Get.find();

  late SharedPreferences _prefs;

  @override
  void onInit() {
    super.onInit();
    _loadDriverStatus();
  }

  Future<void> _loadDriverStatus() async {
    _prefs = await SharedPreferences.getInstance();
    customerStatus.value = _prefs.getInt(CUSTOMER_STATUS) == 1 ? CustomerStatus.online : CustomerStatus.offline;
  }

  Future<void> setDriverOnline() async {
    customerStatus.value = CustomerStatus.online;
    final location = await LocationService.getLocation();
    if (location == null) {
      return;
    }
    _socketController.addDriver(_authController.customerId.value, location);
    await _prefs.setInt(CUSTOMER_STATUS, 1);
  }

  Future<void> setDriverOffline() async {
    customerStatus.value = CustomerStatus.offline;
    _socketController.removeDriver(_authController.customerId.value);
    await _prefs.setInt(CUSTOMER_STATUS, 0);
  }
}
