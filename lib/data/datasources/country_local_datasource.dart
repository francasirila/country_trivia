import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/exceptions/app_exceptions.dart';
import '../models/country.dart';

/// Local data source that loads countries from a bundled JSON asset.
///
/// Used as a fallback when the API is unavailable or no API key is configured.
class CountryLocalDataSource {
  static const String _assetPath = 'assets/data/countries.json';

  /// Loads countries from the local JSON asset file.
  ///
  /// Throws [CacheException] if the file cannot be found or parsed.
  Future<List<Country>> loadCountries() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      return jsonList
          .map((e) => Country.fromLocalJson(e as Map<String, dynamic>))
          .where((c) => c.name.isNotEmpty && c.isoCode.isNotEmpty)
          .toList();
    } catch (e) {
      throw CacheException('Failed to load local data: $e');
    }
  }
}
