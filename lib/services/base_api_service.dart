import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class BaseApiService {
  final String baseUrl;

  BaseApiService(this.baseUrl);

  Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> body) async {
    final String url = '$baseUrl/$endpoint';
    final Map<String, String> headers = {'Content-Type': 'application/json'};

    try {
      final http.Response response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to perform POST request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to perform POST request: $e');
    }
  }

  Future<Map<String, dynamic>> getRequest(String endpoint, {Map<String, dynamic>? parameters}) async {
    final String url = '$baseUrl/$endpoint';
    final Map<String, String> headers = {'Content-Type': 'application/json'};

    try {
      final Uri uri = Uri.parse(url).replace(queryParameters: parameters);
      final http.Response response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to perform GET request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to perform GET request: $e');
    }
  }
}
