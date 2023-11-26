import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grab_customer_app/controllers/firebase_controller.dart';
import 'package:grab_customer_app/services/auth_api_service.dart';
import 'package:grab_customer_app/utils/constants/app_constants.dart';
import 'package:grab_customer_app/utils/constants/ride_constants.dart';
import 'package:grab_customer_app/views/auth/page/phone_verification_page.dart';
import 'package:grab_customer_app/views/auth/page/register_page.dart';
import 'package:grab_customer_app/views/home/page/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final AuthService _authService;
  final FirebaseController _firebaseController = FirebaseController();

  AuthController(this._authService);

  late SharedPreferences _prefs;

  final RxInt customerId = 0.obs;
  final RxString phone = EMPTY_STRING.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  // Load userId from SharedPreferences
  Future<void> _loadUser() async {
    _prefs = await SharedPreferences.getInstance();
    customerId.value = _prefs.getInt(RideConstants.customerId) ?? 0;
  }

  // Save userId to SharedPreferences
  Future<void> _saveUser() async {
    await _prefs.setInt(RideConstants.customerId, customerId.value);
  }

  // Remove userId from SharedPreferences
  Future<void> removeUser() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.remove(RideConstants.customerId);
    await _prefs.remove(CUSTOMER_STATUS);
  }

  // Check if the user exists
  Future<void> checkUser(String phoneNumber) async {
    try {
      final result = await _authService.checkUser(phoneNumber);

      if (result[STATUS] == true) {
        customerId.value = result[DATA][ID];
        _saveUser();
      } else {
        customerId.value = 0;
      }
    } catch (e) {
      // Handle errors during user check
      print('Error checking user: $e');
    }
  }

  // On-board the user with additional details
  Future<void> onBoardUser(String name, BuildContext context) async {
    try {
      final result = await _authService.onBoardUser(phone.value, name, CUSTOMER);

      if (result[STATUS] == true) {
        customerId.value = result[DATA][ID];
        Get.snackbar("Welcome.", "registration successful!", snackPosition: SnackPosition.BOTTOM);
        Get.offAll(() => HomePage());
      } else {
        customerId.value = 0;
      }
    } catch (e) {
      // Handle errors during on-boarding
      print('Error on-boarding user: $e');
    }
  }

  // Verify the phone number using Firebase authentication
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    Get.snackbar("Verifying Number", "Please wait ..");
    await _firebaseController.verifyPhoneNumber(phoneNumber);
    phone.value = phoneNumber;
  }

  // Verify the OTP entered by the user
  Future<void> verifyOtp(String smsCode, BuildContext context) async {
    Get.snackbar("Validating Otp", "Please wait ..");
    try {
      await _firebaseController.verifyOTP(smsCode);
      await checkUser(phone.value);

      if (customerId.value != 0) {
        Get.offAll(() => HomePage());
      } else {
        Get.offAll(() => const RegisterPage());
      }
    } catch (e) {
      print('Lỗi khi xác minh OTP: $e');
      if (e.toString().contains('invalid')) {
        Get.snackbar("Error", "The verification code from SMS/TOTP is invalid");
      } else {
        Get.snackbar("Error", "Cannot verify OTP");
      }
    }
  }

  logOut() {
    customerId.value = 0;
    removeUser();
    Get.offAll(() => const PhoneVerificationPage());
  }
}
