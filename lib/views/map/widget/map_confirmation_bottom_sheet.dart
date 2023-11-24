import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';

class MapConfirmationBottomSheet extends StatelessWidget {
  const MapConfirmationBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final MapController mapController = Get.find();
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const FaIcon(FontAwesomeIcons.longArrowAltRight),
                  Flexible(
                    child: Text(
                      mapController.destinationPlaceName.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
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
                  style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 15),
                ),
                Text(
                  mapController.mapDirectionData[0].durationText.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            // Expanded(
            //   child: mapController.reqAccepted.value
            //       ? DriverDetails(grabMapController: mapController)
            //       : mapController.findDriverLoading.value
            //           ? Lottie.network('https://assets9.lottiefiles.com/packages/lf20_ubozqrue.json')
            //           : ListView.builder(
            //               //shrinkWrap: true,
            //               itemCount: mapController.availableDriversList.length, //2
            //               itemBuilder: (context, index) {
            //                 return Container(
            //                   margin: const EdgeInsets.all(15),
            //                   color: Colors.grey[100],
            //                   child: ListTile(
            //                     contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            //                     leading: Container(
            //                         width: 85,
            //                         padding: const EdgeInsets.only(right: 12.0),
            //                         decoration: const BoxDecoration(
            //                             border: Border(right: BorderSide(width: 1.0, color: Colors.black38))),
            //                         child: mapController.availableDriversList[index].vehicle!.path.split('/').first ==
            //                                 'cars'
            //                             ? Image.asset("assets/car.png")
            //                             : mapController.availableDriversList[index].vehicle!.path.split('/').first ==
            //                                     'auto'
            //                                 ? Image.asset(
            //                                     'assets/auto.png',
            //                                   )
            //                                 : Image.asset(
            //                                     'assets/bike.png',
            //                                   )),
            //                     title: Text(
            //                       mapController.availableDriversList[index].name.toString(),
            //                       // style: const TextStyle(
            //                       //     color: Colors.black, fontWeight: FontWeight.bold),
            //                     ),
            //                     subtitle: mapController.availableDriversList[index].vehicle!.path.split('/').first ==
            //                             'cars'
            //                         ? Text('₹ ${mapController.carRent.value}')
            //                         : mapController.availableDriversList[index].vehicle!.path.split('/').first == 'auto'
            //                             ? Text('₹ ${mapController.autoRent.value}')
            //                             : Text('₹ ${mapController.bikeRent.value}'),
            //                     trailing: Text("${mapController.availableDriversList[index].overallRating} ⭐"),
            //                     onTap: () {
            //                       mapController.generateTrip(mapController.availableDriversList[index], index);
            //                     },
            //                   ),
            //                 );
            //               }),
            // ),
          ],
        ),
      ),
    );
  }
}
