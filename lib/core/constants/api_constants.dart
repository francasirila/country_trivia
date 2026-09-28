/// API-related constants for the Country Trivia app.
class ApiConstants {
  ApiConstants._();

  /// Base URL for the REST Countries v5 API.
  static const String baseUrl = 'https://api.restcountries.com/countries/v5';

  /// Base URL for the flag CDN.
  static const String flagCdnBaseUrl = 'https://flagcdn.com';

  /// Flag image width (pixels).
  static const int flagWidth = 320;

  /// Default page size for API requests.
  static const int defaultPageSize = 100;

  /// Maximum number of pages to fetch (safety limit).
  static const int maxPages = 10;

  /// Request timeout duration.
  static const Duration timeout = Duration(seconds: 15);

  /// API key from environment (set via --dart-define).
  static const String apiKey = String.fromEnvironment(
    'REST_COUNTRIES_API_KEY',
    defaultValue: '',
  );

  /// Returns the flag URL for a given ISO alpha-2 code.
  static String flagUrl(String isoCode) {
    return '$flagCdnBaseUrl/w$flagWidth/${isoCode.toLowerCase()}.png';
  }
}
