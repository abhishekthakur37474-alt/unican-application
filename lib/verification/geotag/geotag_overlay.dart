import 'package:flutter/material.dart';

import 'geotag_data.dart';

const Color _pinRed = Color(0xFFEA4335);

/// The dark, translucent geo-tag panel drawn over the captured photo in the
/// style of the GPS Map Camera app: a map preview on the left and location
/// details in white text on the right.
///
/// Text is never ellipsised here — the panel simply grows vertically so the
/// full address, coordinates and timestamp are always visible.
class GeoTagOverlay extends StatelessWidget {
  final GeoTagData data;

  const GeoTagOverlay({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniMap(
            latitude: data.latitude,
            longitude: data.longitude,
            size: 104,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Line(
                  data.primaryLocation,
                  size: 17,
                  weight: FontWeight.w800,
                  height: 1.18,
                ),
                if (data.addressLine.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _Line(
                    data.addressLine,
                    size: 11.5,
                    weight: FontWeight.w500,
                    height: 1.32,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
                const SizedBox(height: 7),
                _KeyValueRow(value: data.coordinateText),
                const SizedBox(height: 4),
                _KeyValueRow(value: data.dateTimeText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String value;

  const _KeyValueRow({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 11.5,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        shadows: [
          Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final double height;
  final Color color;

  const _Line(
    this.text, {
    this.size = 11.5,
    this.weight = FontWeight.w600,
    this.height = 1.3,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        height: height,
        fontWeight: weight,
        color: color,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double size;

  const _MiniMap({
    required this.latitude,
    required this.longitude,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MiniMapPainter(
                seed: (latitude.abs() * 1000 + longitude.abs() * 1000).round(),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 17,
                  color: _pinRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a lightweight, offline map thumbnail: blocks, roads, a park and a
/// water band, seeded from the coordinates so the tile stays stable for a
/// given location.
class _MiniMapPainter extends CustomPainter {
  final int seed;

  _MiniMapPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFE7EEF3));

    final park = Paint()..color = const Color(0xFFC6E6C9);
    final water = Paint()..color = const Color(0xFFB9D8F2);
    final block = Paint()..color = const Color(0xFFF6F9FB);
    final blockBorder = Paint()
      ..color = const Color(0xFFD4DEE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final road = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final roadEdge = Paint()
      ..color = const Color(0xFFCFDAE2)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.56,
          size.height * 0.05,
          size.width * 0.4,
          size.height * 0.26,
        ),
        const Radius.circular(4),
      ),
      park,
    );

    final waterPath = Path()
      ..moveTo(-2, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.63,
        size.width + 2,
        size.height * 0.82,
      )
      ..lineTo(size.width + 2, size.height + 2)
      ..lineTo(-2, size.height + 2)
      ..close();
    canvas.drawPath(waterPath, water);

    final cell = size.width / 4;
    for (var x = 0; x < 4; x++) {
      for (var y = 0; y < 3; y++) {
        if ((x + y + seed) % 3 == 0) continue;
        final r = Rect.fromLTWH(
          x * cell + 5,
          y * cell + 5,
          cell - 10,
          cell - 10,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(3)),
          block,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(3)),
          blockBorder,
        );
      }
    }

    final diagonal = Path()
      ..moveTo(-size.width * 0.1, size.height * 0.7)
      ..lineTo(size.width * 1.1, size.height * 0.46);
    canvas.drawPath(diagonal, roadEdge);
    canvas.drawPath(diagonal, road);

    final vertical = Offset(size.width * 0.3, -6);
    final verticalEnd = Offset(size.width * 0.3, size.height + 6);
    canvas.drawLine(vertical, verticalEnd, roadEdge);
    canvas.drawLine(vertical, verticalEnd, road);
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
