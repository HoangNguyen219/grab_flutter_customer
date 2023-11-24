import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grab_customer_app/common/internet/internet_controller.dart';
import 'package:grab_customer_app/controllers/auth_controller.dart';
import 'package:grab_customer_app/controllers/home_controller.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/controllers/ride_controller.dart';
import 'package:grab_customer_app/controllers/socket_controller.dart';
import 'package:grab_customer_app/services/auth_api_service.dart';
import 'package:grab_customer_app/services/map_api_service.dart';
import 'package:grab_customer_app/services/ride_api_service.dart';
import 'package:grab_customer_app/services/socket_service.dart';
import 'package:grab_customer_app/views/auth/page/phone_verification_page.dart';
import 'package:grab_customer_app/views/home/page/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthController authController =
  Get.put(AuthController(AuthService(dotenv.env['API_URL'] ?? "http://10.0.2.2:6666")));

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Grab Customer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Obx(() {
        Get.put(InternetController());
        Get.put(MapController(MapService(dotenv.env['MAP_URL'] ?? "https://maps.googleapis.com")));
        Get.put(SocketController(SocketService(dotenv.env['SOCKET_URL'] ?? "ws://10.0.2.2:6666")));
        Get.put(HomeController());
        Get.put(RideController(RideService(dotenv.env['API_URL'] ?? "http://10.0.2.2:6666")));
        return authController.customerId.value != 0 ? const HomePage() : const PhoneVerificationPage();
      }),
    );
  }
}
