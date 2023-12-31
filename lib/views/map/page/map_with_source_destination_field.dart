import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/utils/constants/app_constants.dart';
import 'package:grab_customer_app/views/home/page/home_page.dart';
import 'package:grab_customer_app/views/map/widget/map_confirmation_bottom_sheet.dart';

class MapWithSourceDestinationField extends StatefulWidget {
  final CameraPosition defaultCameraPosition;
  final CameraPosition newCameraPosition;

  const MapWithSourceDestinationField(
      {required this.newCameraPosition, required this.defaultCameraPosition, super.key});

  @override
  MapWithSourceDestinationFieldState createState() => MapWithSourceDestinationFieldState();
}

class MapWithSourceDestinationFieldState extends State<MapWithSourceDestinationField> {
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
                        markers: _mapController.markers.toSet(),
                        polylines: {
                          Polyline(
                              polylineId: const PolylineId("polyLine"),
                              color: Colors.green,
                              width: 6,
                              jointType: JointType.round,
                              startCap: Cap.roundCap,
                              endCap: Cap.roundCap,
                              geodesic: true,
                              points: _mapController.polylineCoordinates),
                          Polyline(
                              polylineId: const PolylineId("polyLineForAcceptDriver"),
                              color: Colors.blueAccent,
                              width: 6,
                              jointType: JointType.round,
                              startCap: Cap.roundCap,
                              endCap: Cap.roundCap,
                              geodesic: true,
                              points: _mapController.polylineCoordinatesForAcceptDriver),
                        },
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: true,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController.googleMapController.complete(controller);
                          controller.animateCamera(CameraUpdate.newCameraPosition(widget.newCameraPosition));
                        },
                      ),
                    ),
                    Visibility(
                        visible: _mapController.bookingState.value != BookingState.isChoosingPlaces &&
                            _mapController.bookingState.value != BookingState.isArrived,
                        child: const SizedBox(height: 250, child: MapConfirmationBottomSheet()))
                  ],
                ),
              ),
              Column(
                children: [
                  Obx(
                    () => Visibility(
                      visible: _mapController.bookingState.value == BookingState.isChoosingPlaces,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        color: Colors.grey[300],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              child: GestureDetector(
                                onTap: () {
                                  Get.off(() => const HomePage());
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
                              margin: const EdgeInsets.symmetric(horizontal: 15),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: const BoxDecoration(
                                  color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(12))),
                              child: TextField(
                                onChanged: (val) {
                                  _mapController.getPredictions(val, SOURCE);
                                },
                                decoration:
                                    const InputDecoration(border: InputBorder.none, hintText: "Enter Source Place"),
                                controller: sourcePlaceController..text = _mapController.sourcePlaceName.value,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 15),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: const BoxDecoration(
                                  color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(12))),
                              child: TextField(
                                onChanged: (val) {
                                  _mapController.getPredictions(val, DESTINATION);
                                },
                                decoration: const InputDecoration(
                                  hintText: "Enter Destination Place",
                                  border: InputBorder.none,
                                ),
                                controller: destinationController..text = _mapController.destinationPlaceName.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => Visibility(
                        visible: _mapController.mapPredictionData.isNotEmpty,
                        child: Container(
                          color: Colors.white,
                          child: ListView.builder(
                              // shrinkWrap: true,
                              itemCount: _mapController.mapPredictionData.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  onTap: () async {
                                    FocusScope.of(context).unfocus();
                                    if (_mapController.predictionListType.value == SOURCE) {
                                      _mapController.setPlaceAndGetLocationDetailsAndDirection(
                                          sourcePlace: _mapController.mapPredictionData[index].mainText.toString(),
                                          destinationPlace: EMPTY_STRING);
                                    } else {
                                      _mapController.setPlaceAndGetLocationDetailsAndDirection(
                                          sourcePlace: EMPTY_STRING,
                                          destinationPlace:
                                              _mapController.mapPredictionData[index].mainText.toString());
                                    }
                                  },
                                  title: Text(_mapController.mapPredictionData[index].mainText.toString()),
                                  subtitle: Text(_mapController.mapPredictionData[index].secondaryText.toString()),
                                  leading: const Icon(Icons.place),
                                );
                              }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
