import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/views/home/page/home_page.dart';
import 'package:grab_customer_app/views/map/widget/map_confirmation_bottom_sheet.dart';

class MapWithSourceDestinationField extends StatefulWidget {
  final CameraPosition defaultCameraPosition;
  final CameraPosition newCameraPosition;

  const MapWithSourceDestinationField(
      {required this.newCameraPosition,
      required this.defaultCameraPosition,
      super.key});

  @override
  _MapWithSourceDestinationFieldState createState() =>
      _MapWithSourceDestinationFieldState();
}

class _MapWithSourceDestinationFieldState
    extends State<MapWithSourceDestinationField> {

  final sourcePlaceController = TextEditingController();
  final destinationController = TextEditingController();

  final MapController _mapController = Get.find();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    sourcePlaceController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => const HomePage());
        _mapController.subscription.cancel();
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Obx(
                () => Column(
                  children: [
                    Expanded(
                      child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: widget.defaultCameraPosition,
                        myLocationButtonEnabled: true,
                        myLocationEnabled: true,
                        markers: _mapController.markers.value.toSet(),
                        polylines: {
                          Polyline(
                              polylineId: const PolylineId("polyLine"),
                              color: Colors.black,
                              width: 6,
                              jointType: JointType.round,
                              startCap: Cap.roundCap,
                              endCap: Cap.roundCap,
                              geodesic: true,
                              points:
                                  _mapController.polylineCoordinates.value),
                          Polyline(
                              polylineId:
                                  const PolylineId("polyLineForAcptDriver"),
                              color: Colors.black,
                              width: 6,
                              jointType: JointType.round,
                              startCap: Cap.roundCap,
                              endCap: Cap.roundCap,
                              geodesic: true,
                              points: _mapController
                                  .polylineCoordinatesForAcceptDriver.value),
                        },
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: true,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController.controller.complete(controller);
                          controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                  widget.newCameraPosition));
                        },
                      ),
                    ),
                    // Visibility(
                    //   visible:
                    //       _mapController.isReadyToDisplayAvlDriver.value,
                    //   child: const SizedBox(
                    //       height: 250, child: MapConfirmationBottomSheet()),
                    // )
                  ],
                ),
              ),
              Column(
                children: [
                  Obx(
                    () => Visibility(
                      visible: !_mapController.isPolyLineDraw.value,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        color: Colors.grey[300],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white),
                              child: GestureDetector(
                                onTap: () {
                                  // _grabMapController.subscription.cancel();
                                  Get.offAll(() => const HomePage());
                                  _mapController.subscription.cancel();
                                },
                                child: const FaIcon(
                                  FontAwesomeIcons.arrowLeft,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12))),
                              child: TextField(
                                // onChanged: (val) {
                                //   _mapController.getPredictions(
                                //       val, 'source');
                                // },
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter Source Place"),
                                controller: sourcePlaceController
                                  ..text =
                                      _mapController.sourcePlaceName.value,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12))),
                              child: TextField(
                                // onChanged: (val) {
                                //   _mapController.getPredictions(
                                //       val, 'destination');
                                // },
                                decoration: const InputDecoration(
                                  hintText: "Enter Destination Place",
                                  border: InputBorder.none,
                                ),
                                controller: destinationController
                                  ..text = _mapController
                                      .destinationPlaceName.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  //if (_grabMapController.grabMapPredictionData.isNotEmpty)
                  Expanded(
                    child: Obx(
                      () => Visibility(
                        visible:
                            _mapController.mapPredictionData.isNotEmpty,
                        child: Container(
                          color: Colors.white,
                          child: ListView.builder(
                              //shrinkWrap: true,
                              itemCount: _mapController
                                  .mapPredictionData.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  // onTap: () async {
                                  //   FocusScope.of(context).unfocus();
                                  //   if (_mapController
                                  //           .predictionListType.value ==
                                  //       'source') {
                                  //     _mapController
                                  //         .setPlaceAndGetLocationDetailsAndDirection(
                                  //             sourcePlace: _mapController
                                  //                 .mapPredictionData[index]
                                  //                 .mainText
                                  //                 .toString(),
                                  //             destinationPlace: "");
                                  //   } else {
                                  //     _mapController
                                  //         .setPlaceAndGetLocationDetailsAndDirection(
                                  //             sourcePlace: "",
                                  //             destinationPlace:
                                  //                 _mapController
                                  //                     .mapPredictionData[
                                  //                         index]
                                  //                     .mainText
                                  //                     .toString());
                                  //   }
                                  // },
                                  title: Text(_mapController
                                      .mapPredictionData[index].mainText
                                      .toString()),
                                  subtitle: Text(_mapController
                                      .mapPredictionData[index]
                                      .secondaryText
                                      .toString()),
                                  trailing: const Icon(Icons.check),
                                );
                              }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: _mapController.isDriverLoading.value,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  margin: const EdgeInsets.only(bottom: 15),
                  child: const Positioned(
                      //bottom: 15,
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.black,
                      ),
                      Text(
                        "  Loading Rides....",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
