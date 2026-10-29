import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/brutal.dart';

class StatusCard extends StatelessWidget {
  final DeviceStatus status;

  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final online = status.isOnline;
    final color = online ? Brutal.green : Brutal.red;
    final age = status.currentAgeSeconds;

    final ageText = status.lastSeen == null
        ? 'Belum pernah menerima data'
        : age < 60
            ? '$age detik sejak data terakhir'
            : '${(age / 60).floor()} menit sejak data terakhir';

    return BrutalCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Brutal.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  online ? Icons.check : Icons.close,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      online ? 'ONLINE / UPDATED' : 'OFFLINE / STALE',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ageText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Brutal.paper,
              border: Border.all(color: Brutal.ink, width: 2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'BATAS STALE ${status.staleAfterSeconds} DETIK',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
