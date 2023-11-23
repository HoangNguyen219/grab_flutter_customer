import 'package:grab_customer_app/utils/constants/app_constants.dart';
import 'package:grab_customer_app/utils/constants/ride_constants.dart';

class Ride {
  final int? id;
  final int? driverId;
  final int? customerId;
  final Map<String, dynamic>? startLocation;
  final Map<String, dynamic>? endLocation;
  final String? startAddress;
  final String? endAddress;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? status;
  final double? distance;
  final int? price;

  Ride({
    this.id,
    this.driverId,
    this.customerId,
    this.startLocation,
    this.endLocation,
    this.startAddress,
    this.endAddress,
    this.startTime,
    this.endTime,
    this.status,
    this.distance,
    this.price,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? startLoc;
    Map<String, dynamic>? endLoc;

    List<String> startLocationValues =
        (json[RideConstants.startLocation] as String).split(RideConstants.splitCharacter);
    double startLat = double.parse(startLocationValues[0]);
    double startLong = double.parse(startLocationValues[1]);
    startLoc = {RideConstants.lat: startLat, RideConstants.long: startLong};

    List<String> endLocationValues = (json[RideConstants.endLocation] as String).split(RideConstants.splitCharacter);
    double endLat = double.parse(endLocationValues[0]);
    double endLong = double.parse(endLocationValues[1]);
    endLoc = {RideConstants.lat: endLat, RideConstants.long: endLong};

    return Ride(
      id: json[ID],
      driverId: json[RideConstants.customerId],
      customerId: json[RideConstants.customerId],
      startLocation: startLoc,
      endLocation: endLoc,
      startAddress: json[RideConstants.startAddress],
      endAddress: json[RideConstants.endAddress],
      startTime: json[RideConstants.startTime] != null ? DateTime.parse(json[RideConstants.startTime]) : null,
      endTime: json[RideConstants.endTime] != null ? DateTime.parse(json[RideConstants.endTime]) : null,
      status: json[RideConstants.status],
      distance: json[RideConstants.distance]?.toDouble(),
      price: json[RideConstants.price],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'customerId': customerId,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'distance': distance,
      'price': price,
    };
  }
}
