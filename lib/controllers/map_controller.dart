import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/models/driver.dart';
import 'package:grab_customer_app/models/map_direction.dart';
import 'package:grab_customer_app/models/map_direction_api_model.dart';
import 'package:grab_customer_app/models/map_prediction.dart';
import 'package:grab_customer_app/services/map_api_service.dart';
import 'package:grab_customer_app/utils/constants/ride_constants.dart';

class MapController extends GetxController {
  final MapService _mapService;

  var mapPredictionData = <MapPrediction>[].obs;

  var mapDirectionData = <MapDirection>[].obs;
  var sourcePlaceName = "".obs;
  var destinationPlaceName = "".obs;
  var predictionListType = "source".obs;

  RxDouble sourceLatitude = 0.0.obs;
  RxDouble sourceLongitude = 0.0.obs;

  RxDouble destinationLatitude = 0.0.obs;
  RxDouble destinationLongitude = 0.0.obs;
  var availableDriversList = <Driver>[].obs;

  // polyline
  var polylineCoordinates = <LatLng>[].obs;
  var polylineCoordinatesForAcceptDriver = <LatLng>[].obs;
  PolylinePoints polylinePoints = PolylinePoints();

  //markers
  var markers = <Marker>[].obs;

  var isPolyLineDraw = false.obs;
  var isReadyToDisplayAvlDriver = false.obs;

  var carRent = 0.obs;
  var bikeRent = 0.obs;
  var autoRent = 0.obs;
  var isDriverLoading = false.obs;
  var findDriverLoading = false.obs;
  var prevTripId = "xyz".obs;

  var reqAccepted = false.obs;

  var reqAcceptedDriverAndVehicleData = <String, String>{};

  final Completer<GoogleMapController> controller = Completer();

  MapController(this._mapService);

  getPredictions(String placeName, String predictionType) async {
    mapPredictionData.clear();
    predictionListType.value = predictionType;
    if (placeName != sourcePlaceName.value || placeName != destinationPlaceName.value) {
      // final predictionList = await _mapService.getGrabMapPrediction(placeName);
      //
      // List<MapPrediction> grabMapPredictionEntityList = [];
      // for (int i = 0; i < predictionList.predictions!.length; i++) {
      //   final predictionData = MapPrediction(
      //       secondaryText: predictionList.predictions![i].structuredFormatting!.secondaryText,
      //       mainText: predictionList.predictions![i].structuredFormatting!.mainText,
      //       placeId: predictionList.predictions![i].placeId);
      //   grabMapPredictionEntityList.add(predictionData);
      //   mapPredictionData.value = grabMapPredictionEntityList;
      mapPredictionData.value = [
        MapPrediction(
          secondaryText: 'Tân Bình, Thành phố Hồ Chí Minh, Vietnam',
          mainText: '144 Âu Cơ, Phường 9',
          placeId: 'abc123',
        ),
        MapPrediction(
          secondaryText: 'Phường 14, Quận 10, Thành phố Hồ Chí Minh, Vietnam',
          mainText: '268 Lý Thường Kiệt, Phường 14',
          placeId: 'def456',
        ),
        MapPrediction(
          secondaryText: 'Quận 1, Hồ Chí Minh',
          mainText: 'Chợ Bến Thành - Cổng Đông',
          placeId: 'ghi789',
        ),
      ];
    }
  }

  setPlaceAndGetLocationDetailsAndDirection({required String sourcePlace, required String destinationPlace}) async {
    mapPredictionData.clear(); // clear list of suggestions
    if (destinationPlace != "") {
      availableDriversList.clear();
      destinationPlaceName.value = destinationPlace;
      List<Location> destinationLocations = await locationFromAddress(destinationPlace); //get destination latlng
      destinationLatitude.value = destinationLocations[0].latitude;
      destinationLongitude.value = destinationLocations[0].longitude;
      addMarkers(destinationLocations[0].latitude, destinationLocations[0].longitude, "destination_marker",
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), "default", "Destination Location");
      animateCamera(destinationLocations[0].latitude, destinationLocations[0].longitude);
    }
    if (sourcePlace != "") {
      availableDriversList.clear();
      sourcePlaceName.value = sourcePlace;
      List<Location> sourceLocations = await locationFromAddress(sourcePlace); //get source latlng
      sourceLatitude.value = sourceLocations[0].latitude;
      sourceLongitude.value = sourceLocations[0].longitude;
      addMarkers(sourceLocations[0].latitude, sourceLocations[0].longitude, "source_marker",
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), "default", "Source Location");
      animateCamera(sourceLocations[0].latitude, sourceLocations[0].longitude);
    }
    if (sourcePlaceName.value.isNotEmpty && destinationPlaceName.value.isNotEmpty) {
      if (sourcePlaceName.value != destinationPlaceName.value) {
        _getDirection();
      } else {
        Get.snackbar("error", "both location can't be same!");
      }
    }
  }

  Future<void> _getDirection() async {
    // Fetch directions
    final directionList = await _mapService.getGrabMapDirection(
      sourceLatitude.value,
      sourceLongitude.value,
      destinationLatitude.value,
      destinationLongitude.value,
    );

    // Process direction data
    List<MapDirection> grabMapDirectionEntityList = _processDirectionList(directionList);
    mapDirectionData.value = grabMapDirectionEntityList;

    // Get drivers within a certain distance
    // updateAvailableDrivers();

    animateCameraPolyline();
    getPolyLine();
  }

  List<MapDirection> _processDirectionList(Direction directionList) {
    return directionList.routes!.map((route) {
      final legs = route.legs![0];
      return MapDirection(
        distanceValue: legs.distance!.value,
        durationValue: legs.duration!.value,
        distanceText: legs.distance!.text,
        durationText: legs.duration!.text,
        enCodedPoints: route.overviewPolyline!.points,
      );
    }).toList();
  }

  void updateAvailableDrivers(List<Driver> onlineDrivers) {
    print("=====================");
    print(onlineDrivers);
    isDriverLoading.value = true;
    List<Driver> driverData = onlineDrivers;
    availableDriversList.clear();

    // Remove extra markers
    if (markers.length > 2) {
      markers.removeRange(2, markers.length - 1);
    }

    // Filter and add nearby drivers
    const double maxDistance = 5000; // Maximum distance in meters
    for (int i = 0; i < driverData.length; i++) {
      double distance = Geolocator.distanceBetween(
        sourceLatitude.value,
        sourceLongitude.value,
        driverData[i].location![RideConstants.lat],
        driverData[i].location![RideConstants.long],
      );

      if (distance < maxDistance) {
        availableDriversList.add(driverData[i]);
        addMarkers(
          driverData[i].location![RideConstants.lat],
          driverData[i].location![RideConstants.long],
          i.toString(),
          'assets/car.png',
          "img",
          "Driver Location",
        );
      }
    }
  }

  getPolyLine() async {
    List<PointLatLng> result = polylinePoints.decodePolyline(mapDirectionData[0].enCodedPoints.toString());
    polylineCoordinates.clear();
    for (var point in result) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
    isPolyLineDraw.value = true;
  }

  addMarkers(double latitude, double longitude, String markerId, icon, String type, String infoWindow) async {
    Marker marker = Marker(
        icon: type == "img" ? BitmapDescriptor.fromBytes(await getBytesFromAsset(icon, 85)) : icon,
        markerId: MarkerId(markerId),
        infoWindow: InfoWindow(title: infoWindow),
        position: LatLng(latitude, longitude));
    markers.add(marker);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  void animateCameraPolyline() async {
    final GoogleMapController _controller = await controller.future;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        min(sourceLatitude.value, destinationLatitude.value),
        min(sourceLongitude.value, destinationLongitude.value),
      ),
      northeast: LatLng(
        max(sourceLatitude.value, destinationLatitude.value),
        max(sourceLongitude.value, destinationLongitude.value),
      ),
    );

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    _controller.animateCamera(cameraUpdate);
  }

  animateCamera(double lat, double lng) async {
    final GoogleMapController _controller = await controller.future;
    CameraPosition newPos = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 11,
    );
    _controller.animateCamera(CameraUpdate.newCameraPosition(newPos));
  }


// generateTrip(GrabDriverEntity driverData, int index) async {
//   grabCancelTripUseCase.call(prevTripId.value, true); // if canceled
//   subscription.pause();
//   String vehicleType = driverData.vehicle!.path.split('/').first;
//   String driverId = driverData.driverId.toString();
//   String customerId = await grabAuthGetUserUidUseCase.call();
//   DocumentReference driverIdRef = FirebaseFirestore.instance.doc("/drivers/${driverId.trim()}");
//   DocumentReference customerIdRef = FirebaseFirestore.instance.doc("/customers/$customerId");
//   var tripId = const Uuid().v4();
//   prevTripId.value = tripId;
//   final generateTripModel = GenerateTripModel(
//       sourcePlaceName.value,
//       destinationPlaceName.value,
//       GeoPoint(sourceLatitude.value, sourceLongitude.value),
//       GeoPoint(destinationLatitude.value, destinationLongitude.value),
//       mapDirectionData[0].distanceValue! / 1000.roundToDouble(),
//       mapDirectionData[0].durationText,
//       false,
//       DateTime.now().toString(),
//       driverIdRef,
//       customerIdRef,
//       0.0,
//       false,
//       vehicleType == 'cars'
//           ? carRent.value
//           : vehicleType == 'auto'
//               ? autoRent.value
//               : bikeRent.value,
//       false,
//       false,
//       tripId);
//   Stream reqStatusData = grabMapGenerateTripUseCase.call(generateTripModel);
//   findDriverLoading.value = true;
//   late StreamSubscription tripSubscription;
//   tripSubscription = reqStatusData.listen((data) async {
//     final reqStatus = data.data()['ready_for_trip'];
//     if (reqStatus) {
//       subscription.cancel();
//     }
//     if (reqStatus && findDriverLoading.value) {
//       subscription.cancel();
//       final reqAcceptedDriverVehicleData =
//           await grabMapGetVehicleDetailsUseCase.call(vehicleType, driverId); // get vehicldata if req accepted
//       reqAcceptedDriverAndVehicleData["name"] = driverData.name.toString();
//       reqAcceptedDriverAndVehicleData["mobile"] = driverData.mobile.toString();
//       reqAcceptedDriverAndVehicleData["vehicle_color"] = reqAcceptedDriverVehicleData.color;
//       reqAcceptedDriverAndVehicleData["vehicle_model"] = reqAcceptedDriverVehicleData.model;
//       reqAcceptedDriverAndVehicleData["vehicle_company"] = reqAcceptedDriverVehicleData.company;
//       reqAcceptedDriverAndVehicleData["vehicle_number_plate"] = reqAcceptedDriverVehicleData.numberPlate.toString();
//       reqAcceptedDriverAndVehicleData["profile_img"] = driverData.profileImg.toString();
//       reqAcceptedDriverAndVehicleData["overall_rating"] = driverData.overallRating.toString();
//       if (markers.length > 2) {
//         markers.removeRange(2, markers.length - 1);
//       } // clear extra marker
//       addMarkers(
//           driverData.currentLocation!.latitude,
//           driverData.currentLocation!.longitude,
//           "acpt_driver_marker",
//           driverData.vehicle!.path.split('/').first == "cars"
//               ? 'assets/car.png'
//               : driverData.vehicle!.path.split('/').first == "bikes"
//                   ? 'assets/bike.png'
//                   : 'assets/auto.png',
//           "img",
//           "Driver Location"); // add only acpt_driver_marker
//
//       // draw path from acpt_driver to consumer
//       final directionData = await grabMapDirectionUsecase.call(driverData.currentLocation!.latitude,
//           driverData.currentLocation!.longitude, sourceLatitude.value, sourceLongitude.value);
//       List<PointLatLng> result = polylinePoints.decodePolyline(directionData[0].enCodedPoints.toString());
//       polylineCoordinatesForAcceptDriver.clear();
//       for (var point in result) {
//         polylineCoordinatesForAcceptDriver.value.add(LatLng(point.latitude, point.longitude));
//       }
//       if (findDriverLoading.value && reqAccepted.value == false) {
//         findDriverLoading.value = false;
//         Get.snackbar(
//           "Yahoo!",
//           "request accepted by driver,driver will arrive within 10 min",
//         );
//         reqAccepted.value = true;
//       }
//     } else if (data.data()['is_arrived'] && !data.data()['is_completed']) {
//       Get.snackbar("driver arrived!", "Now you can track from tripHistory page!",
//           snackPosition: SnackPosition.BOTTOM);
//       tripSubscription.cancel();
//       Get.off(() => const TripHistory());
//     }
//     Timer(const Duration(seconds: 60), () {
//       if (reqStatus == false && findDriverLoading.value) {
//         tripSubscription.cancel();
//         grabCancelTripUseCase.call(tripId, false);
//         // availableDriversList.value.removeAt(index);
//         Get.snackbar("Sorry !", "request denied by driver,please choose other driver",
//             snackPosition: SnackPosition.BOTTOM);
//         subscription.resume();
//         findDriverLoading.value = false;
//       }
//     });
//   });
// }
}
