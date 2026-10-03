import 'package:flutter/material.dart';

import '../services/emergency_alert_service.dart';
import '../services/nearby_mesh_service.dart';
import 'sos_compose_screen.dart';

class SosBroadcastScreen extends StatefulWidget {
  const SosBroadcastScreen({super.key});

  @override
  State<SosBroadcastScreen> createState() => _SosBroadcastScreenState();
}

class _SosBroadcastScreenState extends State<SosBroadcastScreen> {
  @override
  void initState() {
    super.initState();
    EmergencyAlertService().stopAlarm();
  }

  void _openCompose() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosComposeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.radar, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Resque • Mesh SOS',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF14241C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'SOS trafia tylko do innych telefonów z tą aplikacją. Osoby obok bez Resque nie dostaną powiadomienia.',
                style: TextStyle(color: Colors.white, height: 1.35),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Semantics(
                button: true,
                label: 'Otwórz wysyłkę SOS',
                child: GestureDetector(
                  key: const Key('open-sos'),
                  onTap: _openCompose,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sos, size: 52, color: Colors.white),
                        SizedBox(height: 6),
                        Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kliknij, żeby wybrać dane, wiadomość i odbiorców.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 28),
            _buildLinkCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard() {
    return ListenableBuilder(
      listenable: NearbyMeshService(),
      builder: (context, _) {
        final link = NearbyMeshService();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bluetooth_searching, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link.isSupported
                          ? 'Aplikacje Resque w zasięgu: ${link.peersInRange}'
                          : 'Nasłuch w zasięgu: tylko Android',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                link.statusMessage,
                style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.35),
              ),
              if (link.needsSettings) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: link.openSettings,
                  child: const Text('Otwórz ustawienia aplikacji'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
