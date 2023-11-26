import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/common/widget/loading_widget.dart';
import 'package:grab_customer_app/controllers/live_tracking_controller.dart';
import 'package:grab_customer_app/models/ride.dart';

class MapLiveTrackingPage extends StatefulWidget {
  final Ride ride;

  const MapLiveTrackingPage({super.key, required this.ride});

  @override
  _MapLiveTrackingPageState createState() => _MapLiveTrackingPageState();
}

class _MapLiveTrackingPageState extends State<MapLiveTrackingPage> {
  final LiveTrackingController _liveTrackingController = Get.find();

  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(10.77687, 106.70291),
    zoom: 14.4746,
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _liveTrackingController.getDirectionData(widget.ride);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        resizeToAvoidBottomInset: true,
        body: _liveTrackingController.isLoading.value
            ? const LoadingWidget()
            : Stack(
                children: [
                  GoogleMap(
                      mapType: MapType.normal,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: false,
                      initialCameraPosition: _defaultLocation,
                      markers: _liveTrackingController.markers.toSet(),
                      polylines: {
                        Polyline(
                            polylineId: const PolylineId("polyLine"),
                            color: Colors.green,
                            width: 6,
                            jointType: JointType.round,
                            startCap: Cap.roundCap,
                            endCap: Cap.roundCap,
                            geodesic: true,
                            points: _liveTrackingController.polylineCoordinates),
                      },
                      zoomControlsEnabled: false,
                      zoomGesturesEnabled: true,
                      onMapCreated: (GoogleMapController controller) {
                        _liveTrackingController.googleMapController.complete(controller);
                        CameraPosition liveLoc = CameraPosition(
                          target: LatLng(_liveTrackingController.liveLocLatitude.value,
                              _liveTrackingController.liveLocLongitude.value),
                          zoom: 14.4746,
                        );
                        controller.animateCamera(CameraUpdate.newCameraPosition(liveLoc));
                      }),
                  Positioned(
                    left: 10,
                    right: 10,
                    top: 55,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.all(Radius.circular(15))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.ride.startAddress.toString(),
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 25, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const FaIcon(FontAwesomeIcons.longArrowAltRight, color: Colors.white),
                              Flexible(
                                child: Text(
                                  widget.ride.endAddress.toString(),
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 25, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Text(
                                "Remaining :",
                                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              Text(
                                _liveTrackingController.mapDirectionData[0].distanceText.toString(),
                                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                              Text(
                                _liveTrackingController.mapDirectionData[0].durationText.toString(),
                                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        floatingActionButton: Visibility(
          visible: true,
          child: GestureDetector(
            onTap: () {
              _liveTrackingController.getDirectionData(widget.ride);
            },
            child: Container(
                width: 120,
                decoration:
                    const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(25)), color: Colors.black),
                padding: const EdgeInsets.all(10),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.refresh, color: Colors.white),
                    Text(
                      "Refresh",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
