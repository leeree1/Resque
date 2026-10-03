import 'package:flutter/material.dart';

import '../models/sos_packet.dart';

class SosPacketView extends StatelessWidget {
  final SosPacket packet;
  final bool dense;

  const SosPacketView({
    super.key,
    required this.packet,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final lines = packet.sharedLines;
    if (lines.isEmpty) {
      return const Text(
        'Brak dołączonych informacji',
        style: TextStyle(color: Colors.white54),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          Text(
            lines[i].label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            lines[i].value,
            style: TextStyle(
              color: Colors.white,
              fontSize: lines[i].label == 'Wiadomość' ? 18 : 16,
              fontWeight: lines[i].label == 'Wiadomość'
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
          if (i != lines.length - 1) SizedBox(height: dense ? 8 : 12),
        ],
      ],
    );
  }
}
