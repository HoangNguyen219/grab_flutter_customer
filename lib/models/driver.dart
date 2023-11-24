import 'package:grab_customer_app/utils/constants/ride_constants.dart';

class Driver {
  final int driverId;
  final Map<String, dynamic>? location;

  Driver({
    required this.driverId,
    required this.location,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? loc;

    if (json[RideConstants.location] is String) {
      List<String> startLocationValues =
      (json[RideConstants.location] as String).split(RideConstants.splitCharacter);
      double startLat = double.parse(startLocationValues[0]);
      double startLong = double.parse(startLocationValues[1]);
      loc = {RideConstants.lat: startLat, RideConstants.long: startLong};
    } else if (json[RideConstants.location] is Map<String, dynamic>) {
      loc = Map<String, dynamic>.from(json[RideConstants.location]);
    }

    return Driver(
      driverId: json[RideConstants.driverId],
      location: loc
    );
  }

  Map<String, dynamic> toJson() {
    return {
      RideConstants.driverId: driverId,
      RideConstants.location: location
    };
  }
}
