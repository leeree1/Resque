import 'package:flutter/material.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';
import '../services/nearby_mesh_service.dart';

class RelayMonitorScreen extends StatelessWidget {
  const RelayMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bufor Store-and-Forward'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Pasek statusu połączenia
          AnimatedBuilder(
            animation: NearbyMeshService(),
            builder: (context, _) {
              final service = NearbyMeshService();
              return Container(
                padding: const EdgeInsets.all(12),
                color: service.peersInRange > 0 ? Colors.green.shade900 : Colors.grey.shade900,
                child: Row(
                  children: [
                    Icon(
                      service.peersInRange > 0 ? Icons.link : Icons.link_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        service.statusMessage,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Lista odebranych pakietów w czasie rzeczywistym
          Expanded(
            child: StreamBuilder<List<SosPacket>>(
              stream: MeshNodeService().packetsStream,
              initialData: MeshNodeService().getAllPackets(),
              builder: (context, snapshot) {
                final packets = snapshot.data ?? [];

                if (packets.isEmpty) {
                  return const Center(
                    child: Text(
                      'Brak odebranych pakietów SOS w buforze.\nOczekiwanie na sygnał radiowy...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: packets.length,
                  itemBuilder: (context, index) {
                    final pkt = packets[index];
                    final latStr = pkt.latitude?.toStringAsFixed(4) ?? 'n/a';
                    final lngStr = pkt.longitude?.toStringAsFixed(4) ?? 'n/a';

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.warning, color: Colors.white),
                        ),
                        title: Text(
                          '${pkt.senderName} (${pkt.type.name.toUpperCase()})',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          '${pkt.message}\nGPS: $latStr, $lngStr',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Skok: ${pkt.hopCount}',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}