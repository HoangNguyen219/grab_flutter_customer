import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:grab_customer_app/services/firebase_service.dart';
import 'package:grab_customer_app/utils/constants/app_constants.dart';
import 'package:grab_customer_app/views/auth/page/otp_verification_page.dart';

class FirebaseController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  var verId = EMPTY_STRING.obs;

  // Xác thực số điện thoại
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await _firebaseService.verifyPhoneNumber(phoneNumber, _onVerificationCompleted, _onVerificationFailed,
        (verificationId, forceResendingToken) => _onCodeSent(verificationId, phoneNumber), _onCodeAutoRetrievalTimeout);
  }

  // Xác thực mã OTP
  Future<void> verifyOTP(String smsCode) async {
      await _firebaseService.verifyOTP(verId.value, smsCode);
  }

  // Callback khi xác thực số điện thoại thành công
  void _onVerificationCompleted(PhoneAuthCredential credential) {
    // Xử lý logic khi xác thực thành công
  }

  // Callback khi xác thực số điện thoại thất bại
  void _onVerificationFailed(FirebaseAuthException e) {
    Get.snackbar('error', e.code.toString(), snackPosition: SnackPosition.BOTTOM);
  }

  // Callback khi mã xác thực được gửi đi
  void _onCodeSent(String verificationId, String phoneNumber) {
    verId.value = verificationId;
    Get.snackbar('success', "OTP sent to $phoneNumber");
    Get.to(() => const OtpVerificationPage());
  }

  // Callback khi hết thời gian chờ mã xác thực
  void _onCodeAutoRetrievalTimeout(String verificationId) {
    // Xử lý logic khi hết thời gian chờ mã xác thực
  }
}
