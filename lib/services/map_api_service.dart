import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grab_customer_app/models/map_direction_api_model.dart';
import 'package:grab_customer_app/models/map_prediction_api_model.dart';
import 'package:grab_customer_app/services/base_api_service.dart';

class MapService extends BaseApiService {
  MapService(super.baseUrl);

  static String apiKey = dotenv.env['API_KEY'] ?? "";

  Future<PredictionsList> getGrabMapPrediction(String placeName) async {
    try {
      var response = await getRequest('maps/api/place/autocomplete/json',
          parameters: {'input': placeName, 'types': 'geocode', 'key': apiKey});
      return PredictionsList.fromJson(response);
    } catch (error) {
      // Handle the error gracefully or throw it for upper layers to handle
      print('Error in getGrabMapPrediction: $error');
      rethrow; // Throw the error to maintain the flow
    }
  }

  Future<Direction> getGrabMapDirection(
      double sourceLat, double sourceLng, double destinationLat, double destinationLng) async {
    try {
      var response = await getRequest('maps/api/directions/json', parameters: {
        'origin': "$sourceLat, $sourceLng",
        'destination': "$destinationLat, $destinationLng",
        'key': apiKey
      });
      print("=================");
      print(response);
      return Direction.fromJson(response);
    } catch (error) {
      // Handle the error gracefully or throw it for upper layers to handle
      print('Error in getGrabMapDirection: $error');
      rethrow; // Throw the error to maintain the flow
    }
  }
}
