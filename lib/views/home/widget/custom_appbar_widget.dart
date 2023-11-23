import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:grab_customer_app/views/history/page/ride_history_page.dart';

customAppBarWidget() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "Grab",
        style: TextStyle(fontSize: 35, fontWeight: FontWeight.w600),
      ),
      GestureDetector(
        onTap: () {
          Get.to(() => RideHistoryPage());
        },
        child: const FaIcon(
          FontAwesomeIcons.solidUserCircle,
          size: 45,
        ),
      )
    ],
  );
}
