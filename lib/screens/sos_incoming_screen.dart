import 'package:flutter/material.dart';

import '../models/sos_packet.dart';
import '../widgets/sos_packet_view.dart';

class SosIncomingScreen extends StatelessWidget {
  final SosPacket packet;

  const SosIncomingScreen({super.key, required this.packet});

  @override
  Widget build(BuildContext context) {
    final direct = packet.hopCount <= 1;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Odebrane SOS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ODEBRANO W APLIKACJI',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    direct
                        ? 'Prosto z telefonu z Resque w zasięgu.'
                        : 'Przekazane przez aplikację Resque. Skok: ${packet.hopCount}.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SosPacketView(packet: packet),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ID ${packet.id}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'To nie jest powiadomienie systemowe. Telefony obok bez aplikacji Resque tego nie dostały.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Zamknij',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
