import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/brutal.dart';

class ReadingCard extends StatelessWidget {
  final Reading? reading;

  const ReadingCard({super.key, this.reading});

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return const BrutalCard(
        child: Text(
          'BELUM ADA DATA VALID TERSIMPAN',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      );
    }

    final r = reading!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MetricBlock(
            label: 'SUHU',
            value: r.temperature.toStringAsFixed(1),
            unit: '°C',
            icon: Icons.thermostat,
            color: Brutal.yellow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricBlock(
            label: 'KELEMBAPAN',
            value: r.humidity.toStringAsFixed(0),
            unit: '%',
            icon: Icons.water_drop,
            color: Brutal.blue,
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricBlock({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalCard(
      color: color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Brutal.ink),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 42,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
