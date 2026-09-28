import '../../core/constants/api_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../services/api_service.dart';
import '../models/country.dart';

/// Remote data source that fetches countries from the REST Countries v5 API.
class CountryRemoteDataSource {
  final ApiService _apiService;

  CountryRemoteDataSource({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetches all countries from the API with pagination support.
  ///
  /// Uses `response_fields` to minimize payload size.
  /// Throws [ServerException] on API errors.
  /// Throws [NetworkException] on connectivity issues.
  Future<List<Country>> fetchCountries() async {
    final countries = <Country>[];
    int offset = 0;
    bool hasMore = true;
    int pageCount = 0;

    while (hasMore && pageCount < ApiConstants.maxPages) {
      final url = '${ApiConstants.baseUrl}'
          '?response_fields=names.common,codes.alpha_2'
          '&limit=${ApiConstants.defaultPageSize}'
          '&offset=$offset';

      final response = await _apiService.get(url, headers: _apiService.defaultHeaders);
      final data = response['data'] as Map<String, dynamic>?;
      final objects = data?['objects'] as List<dynamic>? ?? [];
      final meta = data?['meta'] as Map<String, dynamic>?;

      for (final obj in objects) {
        final country = Country.fromApiV5(obj as Map<String, dynamic>);
        if (country.name.isNotEmpty && country.isoCode.isNotEmpty) {
          countries.add(country);
        }
      }

      hasMore = meta?['more'] as bool? ?? false;
      offset += ApiConstants.defaultPageSize;
      pageCount++;
    }

    return countries;
  }
}
