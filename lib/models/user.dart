import 'package:grab_customer_app/utils/constants/user_constants.dart';

class User {
  final String userId;
  final String name;
  final String phone;
  final String userType; // "DRIVER" or "CUSTOMER"
  final int maxDistance;

  User({
    required this.userId,
    required this.name,
    required this.phone,
    required this.userType,
    required this.maxDistance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json[UserConstants.userId],
      name: json[UserConstants.name],
      phone: json[UserConstants.phone],
      userType: json[UserConstants.userType],
      maxDistance: json[UserConstants.maxDistance],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      UserConstants.userId: userId,
      UserConstants.name: name,
      UserConstants.phone: phone,
      UserConstants.userType: userType,
      UserConstants.maxDistance: maxDistance,
    };
  }
}
