import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/exceptions/app_exceptions.dart';

/// HTTP client wrapper for making API requests.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Performs a GET request to the given [url] with optional [headers].
  ///
  /// Throws [NetworkException] on connectivity issues.
  /// Throws [ServerException] on non-200 responses.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client.get(
        uri,
        headers: headers,
      ).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ServerException(
          'Request failed with status: ${response.statusCode}',
        );
      }
    } on http.ClientException {
      throw const NetworkException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  /// Returns the default headers including API key if available.
  Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (ApiConstants.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${ApiConstants.apiKey}';
    }
    return headers;
  }

  void dispose() {
    _client.close();
  }
}
