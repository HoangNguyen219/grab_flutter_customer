import 'package:grab_customer_app/utils/constants/ride_constants.dart';

import 'base_api_service.dart';

class RideService extends BaseApiService {
  RideService(super.baseUrl);

  Future<Map<String, dynamic>> createBookingNow(Map<String, dynamic> rideData) async {
    return await postRequest('api/rides', rideData);
  }

  Future<Map<String, dynamic>> cancelRide(String rideId) async {
    final Map<String, dynamic> body = {RideConstants.rideId: rideId};
    return await postRequest('api/rides/cancel', body);
  }

  Future<Map<String, dynamic>> getRides(int customerId) async {
    return await getRequest('api/rides', parameters: {RideConstants.customerId: customerId.toString()});
  }

  Future<Map<String, dynamic>> getCurrentRides(int customerId) async {
    return await getRequest('api/rides/current', parameters: {RideConstants.customerId: customerId.toString()});
  }
}
