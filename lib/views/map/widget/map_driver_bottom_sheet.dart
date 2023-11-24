import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/controllers/ride_controller.dart';
import 'package:grab_customer_app/utils/constants/app_constants.dart';
import 'package:grab_customer_app/views/map/widget/custom_elevated_button.dart';

class MapDriverBottomSheet extends StatelessWidget {
  const MapDriverBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final MapController mapController = Get.find();
    final RideController rideController = Get.find();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(
        () => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: Text(
                      mapController.sourcePlaceName.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const FaIcon(FontAwesomeIcons.longArrowAltRight),
                  Flexible(
                    child: Text(
                      mapController.destinationPlaceName.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                      //maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  mapController.mapDirectionData[0].distanceText.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
                ),
                Text(
                  mapController.mapDirectionData[0].durationText.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text("GrabCar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  ' ${mapController.mapDirectionData[0].distanceValue! * 12} $VND_SIGN',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomElevatedButton(
                  onPressed: () async {
                    await rideController.createBookingNow(mapController.rideRequest.value);
                  },
                  text: 'BOOK', color: Colors.green,
                ),
                CustomElevatedButton(
                  onPressed: () async {
                    mapController.chooseOtherTrip();
                  },
                  text: 'CHOOSE OTHER TRIP', color: Colors.lightBlue,
                )
              ],
            ),

          ],
        ),
      ),
    );
  }
}
