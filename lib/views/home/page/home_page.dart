import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/controllers/home_controller.dart';
import 'package:grab_customer_app/views/home/widget/custom_appbar_widget.dart';
import 'package:grab_customer_app/views/home/widget/ride_options_widget.dart';
import 'package:grab_customer_app/views/home/widget/top_share_location_card_widget.dart';
import 'package:grab_customer_app/views/home/widget/where_to_widget.dart';
import 'package:grab_customer_app/views/map/page/map_with_source_destination_field.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final HomeController _homeController = Get.find();

  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(10.762622, 106.660172),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _homeController.getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            children: [
              const SizedBox(height: 15),
              customAppBarWidget(),
              const SizedBox(height: 15),
              topShareLocationCardWidget(_homeController),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => _openMapWithCameraPosition(_homeController.currentLat.value, _homeController.currentLng.value),
                child: rideOptionsWidget(),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => _openMapWithCameraPosition(_homeController.currentLat.value, _homeController.currentLng.value),
                child: whereToWidget(),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  child: const FaIcon(
                    FontAwesomeIcons.solidStar,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
                title: const Text(
                  "Choose saved place",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                ),
                trailing: const FaIcon(
                  FontAwesomeIcons.arrowRight,
                  color: Colors.black,
                  size: 18,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Around You",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  child: Obx(() {
                    final isVisible = _homeController.currentLat.value != 0.0;
                    return Visibility(
                      visible: isVisible,
                      child: GoogleMap(
                        onTap: _handleMapTap,
                        mapType: MapType.normal,
                        initialCameraPosition: _defaultLocation,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: true,
                        onMapCreated: (GoogleMapController controller) => _homeController.googleMapController.complete(controller),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMapWithCameraPosition(double lat, double lng) {
    final newCameraPos = CameraPosition(target: LatLng(lat, lng), zoom: 14.4746);
    Get.to(() => MapWithSourceDestinationField(newCameraPosition: newCameraPos, defaultCameraPosition: _defaultLocation));
  }

  void _handleMapTap(LatLng latLng) {
    final currentLat = _homeController.currentLat.value;
    final currentLng = _homeController.currentLng.value;
    _openMapWithCameraPosition(currentLat, currentLng);
  }
}
