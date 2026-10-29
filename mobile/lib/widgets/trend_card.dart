import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/brutal.dart';

class TrendCard extends StatelessWidget {
  final Trend trend;

  const TrendCard({super.key, required this.trend});

  static const _labels = {
    'naik': 'NAIK',
    'turun': 'TURUN',
    'stabil': 'STABIL',
    'insufficient_data': 'BELUM CUKUP',
  };

  @override
  Widget build(BuildContext context) {
    final isUp = trend.trend == 'naik';
    final isDown = trend.trend == 'turun';
    final color = isUp
        ? Brutal.orange
        : isDown
            ? Brutal.blue
            : trend.trend == 'stabil'
                ? Brutal.green
                : const Color(0xFFE5E5E5);
    final icon = isUp
        ? Icons.north_east
        : isDown
            ? Icons.south_east
            : Icons.east;

    return BrutalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TREN SUHU',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Brutal.paper,
                  border: Border.all(color: Brutal.ink, width: 2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${trend.window} DATA',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Brutal.ink, width: 3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 30, color: Brutal.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labels[trend.trend] ?? trend.trend.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trend.slope == null
                          ? 'Butuh minimal ${trend.window} pembacaan'
                          : 'SLOPE ${trend.slope! >= 0 ? '+' : ''}'
                              '${trend.slope!.toStringAsFixed(2)} °C/DATA',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trend.temperatures.length >= 2) ...[
            const SizedBox(height: 16),
            Container(
              height: 74,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Brutal.bg,
                border: Border.all(color: Brutal.ink, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(8),
              child: CustomPaint(
                painter: _SparklinePainter(trend.temperatures, color),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            trend.explanation,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.01 ? 1.0 : (max - min);
    final dx = size.width / (values.length - 1);

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * dx,
          size.height - ((values[i] - min) / range) * (size.height - 10) - 5,
        ),
    ];

    final area = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.55));

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = Brutal.ink
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter,
    );

    for (final p in points) {
      canvas.drawRect(
        Rect.fromCenter(center: p, width: 7, height: 7),
        Paint()..color = Brutal.ink,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
