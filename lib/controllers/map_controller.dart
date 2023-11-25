import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/controllers/auth_controller.dart';
import 'package:grab_customer_app/models/driver.dart';
import 'package:grab_customer_app/models/map_direction.dart';
import 'package:grab_customer_app/models/map_direction_api_model.dart';
import 'package:grab_customer_app/models/map_prediction.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/services/map_api_service.dart';
import 'package:grab_customer_app/utils/constants/ride_constants.dart';

enum BookingState {
  isChoosingPlaces,
  isReadyToBook,
  isBooked,
  isAccepted,
  isArrived,
}

class MapController extends GetxController {
  final MapService _mapService;
  final AuthController _authController = Get.find();
  final Completer<GoogleMapController> controller = Completer();

  var mapPredictionData = <MapPrediction>[].obs;
  var mapDirectionData = <MapDirection>[].obs;
  var sourcePlaceName = "".obs;
  var destinationPlaceName = "".obs;
  var predictionListType = "source".obs;

  RxDouble sourceLatitude = 0.0.obs;
  RxDouble sourceLongitude = 0.0.obs;
  RxDouble destinationLatitude = 0.0.obs;
  RxDouble destinationLongitude = 0.0.obs;


  // polyline
  var polylineCoordinates = <LatLng>[].obs;
  var polylineCoordinatesForAcceptDriver = <LatLng>[].obs;
  PolylinePoints polylinePoints = PolylinePoints();

  //markers
  var markers = <Marker>[].obs;

  var rideRequest = Ride().obs;

  var bookingState = BookingState.isChoosingPlaces.obs;
  var acceptedDriver = Driver().obs;

  MapController(this._mapService);

  chooseOtherTrip() {
    bookingState.value = BookingState.isChoosingPlaces;
  }

  getPredictions(String placeName, String predictionType) async {
    mapPredictionData.clear();
    predictionListType.value = predictionType;
    if (placeName != sourcePlaceName.value || placeName != destinationPlaceName.value) {
      final predictionList = await _mapService.getGrabMapPrediction(placeName);

      List<MapPrediction> grabMapPredictionEntityList = [];
      for (int i = 0; i < predictionList.predictions!.length; i++) {
        final predictionData = MapPrediction(
            secondaryText: predictionList.predictions![i].structuredFormatting!.secondaryText,
            mainText: predictionList.predictions![i].structuredFormatting!.mainText,
            placeId: predictionList.predictions![i].placeId);
        grabMapPredictionEntityList.add(predictionData);
        mapPredictionData.value = grabMapPredictionEntityList;
      }
      // mapPredictionData.value = [
      //   MapPrediction(
      //     secondaryText: 'Tân Bình, Thành phố Hồ Chí Minh, Vietnam',
      //     mainText: '144 Âu Cơ, Phường 9',
      //     placeId: 'abc123',
      //   ),
      //   MapPrediction(
      //     secondaryText: 'Phường 14, Quận 10, Thành phố Hồ Chí Minh, Vietnam',
      //     mainText: '268 Lý Thường Kiệt, Phường 14',
      //     placeId: 'def456',
      //   ),
      //   MapPrediction(
      //     secondaryText: 'Quận 1, Hồ Chí Minh',
      //     mainText: 'Chợ Bến Thành - Cổng Đông',
      //     placeId: 'ghi789',
      //   ),
      // ];
    }
  }

  setPlaceAndGetLocationDetailsAndDirection({required String sourcePlace, required String destinationPlace}) async {
    mapPredictionData.clear(); // clear list of suggestions
    if (destinationPlace != "") {
      destinationPlaceName.value = destinationPlace;
      List<Location> destinationLocations = await locationFromAddress(destinationPlace); //get destination latlng
      destinationLatitude.value = destinationLocations[0].latitude;
      destinationLongitude.value = destinationLocations[0].longitude;
      addMarkers(destinationLocations[0].latitude, destinationLocations[0].longitude, "destination_marker",
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), "default", "Destination Location");
      animateCamera(destinationLocations[0].latitude, destinationLocations[0].longitude);
    }
    if (sourcePlace != "") {
      sourcePlaceName.value = sourcePlace;
      List<Location> sourceLocations = await locationFromAddress(sourcePlace); //get source latlng
      sourceLatitude.value = sourceLocations[0].latitude;
      sourceLongitude.value = sourceLocations[0].longitude;
      addMarkers(sourceLocations[0].latitude, sourceLocations[0].longitude, "source_marker",
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), "default", "Source Location");
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
    List<MapDirection> mapDirectionList = _processDirectionList(directionList);
    mapDirectionData.value = mapDirectionList;

    animateCameraPolyline();
    getPolyLine();
    updateRideRequest();
    bookingState.value = BookingState.isReadyToBook;
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
    List<Driver> driverData = onlineDrivers;

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

  void updateRideRequest() {
    rideRequest.value = Ride(
        customerId: _authController.customerId.value,
        startLocation: {RideConstants.lat: sourceLatitude.value, RideConstants.long: sourceLongitude.value},
        endLocation: {RideConstants.lat: destinationLatitude.value, RideConstants.long: destinationLongitude.value},
        startAddress: sourcePlaceName.value,
        endAddress: destinationPlaceName.value,
        distance: mapDirectionData[0].distanceValue! / 1000,
        price: mapDirectionData[0].distanceValue! * RideConstants.priceFactor);
  }

  void drawPathFromDriver() async {
    final directionList = await _mapService.getGrabMapDirection(
      acceptedDriver.value.location![RideConstants.lat],
      acceptedDriver.value.location![RideConstants.long],
      sourceLongitude.value,
      sourceLatitude.value,
    );
    List<MapDirection> directionData = _processDirectionList(directionList);
    List<PointLatLng> result = polylinePoints
        .decodePolyline(directionData[0].enCodedPoints.toString());
    polylineCoordinatesForAcceptDriver.clear();
    for (var point in result) {
      polylineCoordinatesForAcceptDriver.add(LatLng(point.latitude, point.longitude));
    }
  }
}
