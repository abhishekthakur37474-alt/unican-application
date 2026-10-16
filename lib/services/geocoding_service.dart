import 'dart:convert';

import 'package:http/http.dart' as http;

/// A reverse-geocoded address for a GPS coordinate.
class GeoAddress {
  /// Short "City, State, Country" style label used as the badge headline.
  final String primary;

  /// Full formatted address line.
  final String full;

  const GeoAddress({required this.primary, required this.full});
}

/// Resolves GPS coordinates into a human-readable address using the
/// OpenStreetMap Nominatim reverse-geocoding API. No API key is required.
///
/// Results are cached per rounded coordinate so repeated captures at the same
/// spot do not hit the network again. When the service is unreachable the
/// caller falls back to the raw coordinates.
class GeocodingService {
  GeocodingService._();

  static final GeocodingService instance = GeocodingService._();

  static const String _endpoint =
      'https://nominatim.openstreetmap.org/reverse';

  final Map<String, GeoAddress> _cache = {};

  Future<GeoAddress?> reverseGeocode(double latitude, double longitude) async {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse(_endpoint).replace(
        queryParameters: <String, String>{
          'format': 'jsonv2',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
        },
      );

      final response = await http.get(
        uri,
        headers: const <String, String>{
          'User-Agent': 'Unican-Verification-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      final full = (decoded['display_name'] ?? '').toString().trim();
      final primary = _buildPrimary(decoded['address'], full);
      if (full.isEmpty && primary.isEmpty) return null;

      final result = GeoAddress(
        primary: primary.isEmpty ? full : primary,
        full: full.isEmpty ? primary : full,
      );
      _cache[key] = result;
      return result;
    } catch (_) {
      return null;
    }
  }

  String _buildPrimary(dynamic address, String fallback) {
    if (address is! Map) return fallback;

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final city = pick([
      'city',
      'town',
      'village',
      'municipality',
      'suburb',
      'county',
      'state_district',
    ]);
    final state = pick(['state', 'region']);
    final country = pick(['country']);

    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty && state != city) state,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }
}
