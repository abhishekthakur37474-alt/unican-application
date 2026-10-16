/// Immutable metadata burned onto a captured photo's geo-tag badge.
class GeoTagData {
  /// Short "City, State, Country" headline resolved from the GPS coordinates.
  final String primaryLocation;

  /// Full reverse-geocoded address. Empty when geocoding is unavailable.
  final String addressLine;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;

  const GeoTagData({
    required this.primaryLocation,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
  });

  /// Builds badge data from GPS coordinates plus an optional reverse-geocoded
  /// address. When no address is available the coordinates become the headline.
  factory GeoTagData.fromLocation({
    required double latitude,
    required double longitude,
    String? primaryLocation,
    String? detailedAddress,
    DateTime? capturedAt,
  }) {
    final coordFallback =
        '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    final primary = (primaryLocation ?? '').trim();
    final detailed = (detailedAddress ?? '').trim();

    return GeoTagData(
      primaryLocation: primary.isNotEmpty ? primary : coordFallback,
      addressLine: detailed,
      latitude: latitude,
      longitude: longitude,
      capturedAt: capturedAt ?? DateTime.now(),
    );
  }

  String get latitudeText => latitude.toStringAsFixed(6);

  String get longitudeText => longitude.toStringAsFixed(6);

  String get coordinateText => 'Lat $latitudeText, Long $longitudeText';

  String get timezoneLabel {
    final offset = capturedAt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return 'GMT$sign$hours:$minutes';
  }

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get dateTimeText {
    final weekday = _weekdays[capturedAt.weekday - 1];
    final day = capturedAt.day.toString().padLeft(2, '0');
    final month = capturedAt.month.toString().padLeft(2, '0');
    final year = capturedAt.year;
    final hourOfPeriod = capturedAt.hour % 12 == 0 ? 12 : capturedAt.hour % 12;
    final hour = hourOfPeriod.toString().padLeft(2, '0');
    final minute = capturedAt.minute.toString().padLeft(2, '0');
    final period = capturedAt.hour < 12 ? 'AM' : 'PM';
    return '$weekday, $day/$month/$year $hour:$minute $period $timezoneLabel';
  }
}
