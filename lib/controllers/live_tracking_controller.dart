import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grab_customer_app/controllers/map_controller.dart';
import 'package:grab_customer_app/models/map_direction.dart';
import 'package:grab_customer_app/models/map_direction_api_model.dart';
import 'package:grab_customer_app/models/ride.dart';
import 'package:grab_customer_app/services/map_api_service.dart';
import 'package:grab_customer_app/utils/constants/ride_constants.dart';
import 'package:grab_customer_app/utils/location_service.dart';

class LiveTrackingController extends GetxController {
  final MapService _mapService;

  var liveLocLatitude = 0.0.obs;
  var liveLocLongitude = 0.0.obs;
  var destinationLat = 0.0.obs;
  var destinationLng = 0.0.obs;

  var mapDirectionData = <MapDirection>[].obs;
  var isLoading = true.obs;
  var markers = <Marker>[].obs;

  var polylineCoordinates = <LatLng>[].obs;
  PolylinePoints polylinePoints = PolylinePoints();

  final Completer<GoogleMapController> controller = Completer();

  LiveTrackingController(this._mapService);

  getDirectionData(Ride ride) async {
    checkTripCompletionStatus(ride);
    final position = await LocationService.getLocation();

    if (position == null) {
      // Handle the case where the location permission is denied or null
      return;
    }
    liveLocLatitude.value = position.latitude;
    liveLocLongitude.value = position.longitude;
    destinationLat.value = ride.endLocation![RideConstants.lat];
    destinationLng.value = ride.endLocation![RideConstants.long];

    final directionList = await _mapService.getGrabMapDirection(
        liveLocLatitude.value, liveLocLongitude.value, destinationLat.value, destinationLng.value);

    // Process direction data
    List<MapDirection> mapDirectionList = _processDirectionList(directionList);
    mapDirectionData.value = mapDirectionList;

    addMarkers(BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/car.png', 85)), "live_marker",
        liveLocLatitude.value, liveLocLongitude.value, "Your Location");
    addMarkers(BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), "destination_marker",
        destinationLat.value, destinationLng.value, "Destination Location");
    addPolyLine();
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

  addPolyLine() async {
    List<PointLatLng> result = polylinePoints.decodePolyline(mapDirectionData[0].enCodedPoints.toString());
    polylineCoordinates.clear();
    for (var point in result) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }
    final GoogleMapController _controller = await controller.future;
    CameraPosition liveLoc = CameraPosition(
      target: LatLng(liveLocLatitude.value, liveLocLongitude.value),
      zoom: 16,
    );
    _controller.animateCamera(CameraUpdate.newCameraPosition(liveLoc));
  }

  checkTripCompletionStatus(Ride ride) {}

  addMarkers(icon, String markerId, double lat, double lng, String infoWindow) async {
    Marker marker = Marker(
        icon: icon,
        markerId: MarkerId(markerId),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: infoWindow));
    markers.add(marker);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
}
