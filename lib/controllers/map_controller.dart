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
import 'package:grab_customer_app/utils/constants/app_constants.dart';
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

  final Completer<GoogleMapController> googleMapController = Completer();

  final mapPredictionData = <MapPrediction>[].obs;
  final mapDirectionData = <MapDirection>[].obs;
  final sourcePlaceName = EMPTY_STRING.obs;
  final destinationPlaceName = EMPTY_STRING.obs;
  final predictionListType = SOURCE.obs;

  final sourceLatitude = RxDouble(0.0);
  final sourceLongitude = RxDouble(0.0);
  final destinationLatitude = RxDouble(0.0);
  final destinationLongitude = RxDouble(0.0);

  // polyline
  final polylineCoordinates = <LatLng>[].obs;
  final polylineCoordinatesForAcceptDriver = <LatLng>[].obs;
  PolylinePoints polylinePoints = PolylinePoints();

  //markers
  final markers = <Marker>[].obs;

  final rideRequest = Ride().obs;

  final bookingState = BookingState.isChoosingPlaces.obs;
  final acceptedDriver = Driver().obs;
  final onlineDrivers = <Driver>[].obs;

  MapController(this._mapService);

  resetForNewTrip() {
    bookingState.value = BookingState.isChoosingPlaces;
    mapPredictionData.clear();
    mapDirectionData.clear();
    sourcePlaceName.value = EMPTY_STRING;
    destinationPlaceName.value = EMPTY_STRING;
    sourceLatitude.value = 0.0;
    sourceLongitude.value = 0.0;
    destinationLatitude.value = 0.0;
    destinationLongitude.value = 0.0;
    polylineCoordinates.clear();
    polylineCoordinatesForAcceptDriver.clear();
    markers.clear();
    rideRequest.value = Ride();
    acceptedDriver.value = Driver();
  }

  chooseOtherTrip() {
    bookingState.value = BookingState.isChoosingPlaces;
  }

  getPredictions(String placeName, String predictionType) async {
    mapPredictionData.clear();
    predictionListType.value = predictionType;
    if (placeName != sourcePlaceName.value || placeName != destinationPlaceName.value) {
      final predictionList = await _mapService.getGrabMapPrediction(placeName);

      List<MapPrediction> grabMapPredictionList = [];
      for (int i = 0; i < predictionList.predictions!.length; i++) {
        final predictionData = MapPrediction(
            secondaryText: predictionList.predictions![i].structuredFormatting!.secondaryText,
            mainText: predictionList.predictions![i].structuredFormatting!.mainText,
            placeId: predictionList.predictions![i].placeId);
        grabMapPredictionList.add(predictionData);
      }
      mapPredictionData.value = grabMapPredictionList;
    }
  }

  setPlaceAndGetLocationDetailsAndDirection({required String sourcePlace, required String destinationPlace}) async {
    mapPredictionData.clear(); // clear list of suggestions
    if (destinationPlace != EMPTY_STRING) {
      destinationPlaceName.value = destinationPlace;
      List<Location> destinationLocations = await locationFromAddress(destinationPlace);
      destinationLatitude.value = destinationLocations[0].latitude;
      destinationLongitude.value = destinationLocations[0].longitude;
      _addMarkers(destinationLatitude.value, destinationLongitude.value, "destination_marker",
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), "default", "Destination Location");
      _animateCamera(destinationLatitude.value, destinationLongitude.value);
    }
    if (sourcePlace != EMPTY_STRING) {
      sourcePlaceName.value = sourcePlace;
      List<Location> sourceLocations = await locationFromAddress(sourcePlace);
      sourceLatitude.value = sourceLocations[0].latitude;
      sourceLongitude.value = sourceLocations[0].longitude;
      _addMarkers(sourceLatitude.value, sourceLongitude.value, "source_marker",
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), "default", "Source Location");
      _animateCamera(sourceLatitude.value, sourceLongitude.value);
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

    _animateCameraPolyline();
    _getPolyLine();
    _updateRideRequest();
    _addDriverMarkers();

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

  void updateAvailableDrivers(List<Driver> onlineDriversList) {
    onlineDrivers.value = onlineDriversList;
    _addDriverMarkers();
  }

  void _addDriverMarkers() {
    // Remove extra markers
    if (markers.length > 2) {
      markers.removeRange(2, markers.length);
    }

    // Filter and add nearby drivers
    const double maxDistance = 5000; // Maximum distance in meters
    for (int i = 0; i < onlineDrivers.length; i++) {
      double distance = Geolocator.distanceBetween(
        sourceLatitude.value,
        sourceLongitude.value,
        onlineDrivers[i].location![RideConstants.lat],
        onlineDrivers[i].location![RideConstants.long],
      );

      if (distance < maxDistance) {
        _addMarkers(
          onlineDrivers[i].location![RideConstants.lat],
          onlineDrivers[i].location![RideConstants.long],
          i.toString(),
          'assets/car.png',
          "img",
          "Driver Location",
        );
      }
    }
  }

  void _addAcceptedDriverMarker() {
    // Remove extra markers
    if (markers.length > 2) {
      markers.removeRange(2, markers.length);
    }

    _addMarkers(
      acceptedDriver.value.location![RideConstants.lat],
      acceptedDriver.value.location![RideConstants.long],
      'AcceptedDriverMarker',
      'assets/car.png',
      "img",
      "Driver Location",
    );
  }

  _getPolyLine() async {
    List<PointLatLng> result = polylinePoints.decodePolyline(mapDirectionData[0].enCodedPoints.toString());
    polylineCoordinates.clear();
    for (var point in result) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
  }

  _addMarkers(double latitude, double longitude, String markerId, icon, String type, String infoWindow) async {
    Marker marker = Marker(
        icon: type == "img" ? BitmapDescriptor.fromBytes(await _getBytesFromAsset(icon, 85)) : icon,
        markerId: MarkerId(markerId),
        infoWindow: InfoWindow(title: infoWindow),
        position: LatLng(latitude, longitude));
    markers.add(marker);
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  void _animateCameraPolyline() async {
    final GoogleMapController controller = await googleMapController.future;

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
    controller.animateCamera(cameraUpdate);
  }

  _animateCamera(double lat, double lng) async {
    try {
      final GoogleMapController controller = await googleMapController.future;
      CameraPosition newPos = CameraPosition(
        target: LatLng(lat, lng),
        zoom: 11,
      );
      controller.animateCamera(CameraUpdate.newCameraPosition(newPos));
    } catch (e) {
      print(e);
    }
  }

  void _updateRideRequest() {
    rideRequest.value = Ride(
        customerId: _authController.customerId.value,
        startLocation: {RideConstants.lat: sourceLatitude.value, RideConstants.long: sourceLongitude.value},
        endLocation: {RideConstants.lat: destinationLatitude.value, RideConstants.long: destinationLongitude.value},
        startAddress: sourcePlaceName.value,
        endAddress: destinationPlaceName.value,
        distance: mapDirectionData[0].distanceValue! / 1000,
        price: mapDirectionData[0].distanceValue! * RideConstants.priceFactor);
  }

  void updateAcceptedDriver(Driver driver) {
    acceptedDriver.value = driver;
    _addAcceptedDriverMarker();
    _drawPathFromDriver();
  }

  void _drawPathFromDriver() async {
    final directionList = await _mapService.getGrabMapDirection(
      acceptedDriver.value.location![RideConstants.lat],
      acceptedDriver.value.location![RideConstants.long],
      sourceLatitude.value,
      sourceLongitude.value,
    );
    List<MapDirection> directionData = _processDirectionList(directionList);
    List<PointLatLng> result = polylinePoints.decodePolyline(directionData[0].enCodedPoints.toString());
    polylineCoordinatesForAcceptDriver.clear();
    for (var point in result) {
      polylineCoordinatesForAcceptDriver.add(LatLng(point.latitude, point.longitude));
    }
  }
}
