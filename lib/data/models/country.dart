import '../../core/constants/api_constants.dart';

/// Data model representing a country.
///
/// Supports parsing from both the REST Countries v5 API response
/// and the local JSON fallback format.
class Country {
  /// The common name of the country (e.g., "Germany").
  final String name;

  /// The ISO 3166-1 alpha-2 code (e.g., "DE").
  final String isoCode;

  const Country({
    required this.name,
    required this.isoCode,
  });

  /// Creates a [Country] from a REST Countries v5 API response object.
  ///
  /// The v5 API returns a JSON:API-like structure:
  /// ```json
  /// {
  ///   "names": { "common": "Germany" },
  ///   "codes": { "alpha_2": "DE" }
  /// }
  /// ```
  factory Country.fromApiV5(Map<String, dynamic> json) {
    final names = json['names'] as Map<String, dynamic>?;
    final codes = json['codes'] as Map<String, dynamic>?;

    return Country(
      name: names?['common'] as String? ?? '',
      isoCode: codes?['alpha_2'] as String? ?? '',
    );
  }

  /// Creates a [Country] from the local JSON fallback format.
  ///
  /// Expected format:
  /// ```json
  /// {
  ///   "name": "Germany",
  ///   "isoCode": "DE"
  /// }
  /// ```
  factory Country.fromLocalJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String? ?? '',
      isoCode: json['isoCode'] as String? ?? '',
    );
  }

  /// Returns the URL for the country's flag image.
  String get flagUrl => ApiConstants.flagUrl(isoCode);

  /// Converts the country to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isoCode': isoCode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country &&
        other.name == name &&
        other.isoCode == isoCode;
  }

  @override
  int get hashCode => name.hashCode ^ isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
