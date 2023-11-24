import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grab_customer_app/models/map_direction_api_model.dart';
import 'package:grab_customer_app/models/map_prediction_api_model.dart';
import 'package:grab_customer_app/services/base_api_service.dart';
import 'package:grab_customer_app/variable.dart';

class MapService extends BaseApiService {
  MapService(super.baseUrl);

  static String apiKey = dotenv.env['API_KEY'] ?? "AIzaSyCkWlGDvftO896OXUQN_g485-a39PET8e8";

  Future<PredictionsList> getGrabMapPrediction(String placeName) async {
    var response = await getRequest('maps/api/place/autocomplete/json',
        parameters: {'input': placeName, 'types': 'geocode', 'key': apiKey});
    return PredictionsList.fromJson(response);
  }

  Future<Direction> getGrabMapDirection(
      double sourceLat, double sourceLng, double destinationLat, double destinationLng) async {
    // var response = await getRequest('maps/api/directions/json', parameters: {
    //   'origin': "$sourceLat,$sourceLng",
    //   'destination': "$destinationLat, $destinationLng",
    //   'key': apiKey
    // });
    return Direction.fromJson(getDirectionDetailsFromAPIData);
  }
}
