import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';

class RelayMonitorScreen extends StatelessWidget {
  const RelayMonitorScreen({super.key});

  void _simulateIncomingPacket() {
    final fakePacket = SosPacket(
      id: 'SOS-${DateTime.now().millisecond}',
      senderName: 'Sąsiad (Piętro 3)',
      type: EmergencyType.trapped,
      message: 'Zalana klatka schodowa, brak prądu',
      latitude: 51.1100,
      longitude: 17.0320,
      timestamp: DateTime.now(),
      hopCount: 1,
    );

    MeshNodeService().onPacketReceivedFromPeer(jsonEncode(fakePacket.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    final mesh = MeshNodeService();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Węzeł Przekaźnikowy (Mesh Relay)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.greenAccent),
            tooltip: 'Wypchnij do serwera (Złapano sieć)',
            onPressed: () async {
              await mesh.flushToCentralServer();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text('Zsynchronizowano pakiety z centralnym serwerem ratunkowym!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SosPacket>>(
        stream: mesh.packetsStream,
        initialData: const [],
        builder: (context, snapshot) {
          final packets = snapshot.data ?? [];

          if (packets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hub_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('Brak zbuforowanych pakietów SOS', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _simulateIncomingPacket,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Symuluj odebranie pakietu BLE'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_alt, color: Colors.cyanAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pakiety w buforze: ${packets.length}. Zostaną przesłane do służb, gdy którykolwiek węzeł złapie zasięg.',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...packets.map((pkt) => _buildPacketCard(pkt)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _simulateIncomingPacket,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222222)),
                icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
                label: const Text('Symuluj skok kolejnego pakietu (Hop)', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPacketCard(SosPacket pkt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${pkt.id} • ${pkt.senderName}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Skok: ${pkt.hopCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(pkt.message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
              const SizedBox(width: 4),
              Text('${pkt.latitude.toStringAsFixed(4)}, ${pkt.longitude.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const Spacer(),
              Text(
                '${pkt.timestamp.hour.toString().padLeft(2, '0')}:${pkt.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}