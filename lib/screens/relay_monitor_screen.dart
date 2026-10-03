import 'package:flutter/material.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';

class RelayMonitorScreen extends StatelessWidget {
  const RelayMonitorScreen({super.key});

  String _requestTitle(SosPacket packet) {
    if (!packet.shareType) return 'Osoba potrzebująca pomocy';
    return switch (packet.type) {
      EmergencyType.medical => 'Potrzebna pomoc medyczna',
      EmergencyType.fire => 'Zagrożenie pożarem',
      EmergencyType.flood => 'Zagrożenie powodzią',
      EmergencyType.trapped => 'Osoba uwięziona',
      EmergencyType.other => 'Osoba potrzebująca pomocy',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zgłoszenia SOS'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              'Twój telefon pomaga przekazywać prośby o pomoc innym osobom w pobliżu.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
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
                      'Nie ma jeszcze zgłoszeń SOS.\nTutaj pojawią się prośby o pomoc.',
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
                    final location = pkt.locationLabel;

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Icon(Icons.warning, color: Colors.white),
                        ),
                        title: Text(
                          _requestTitle(pkt),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (pkt.shareMessage &&
                                pkt.message.trim().isNotEmpty)
                              pkt.message.trim(),
                            if (location != null) 'Lokalizacja: $location',
                          ].join('\n'),
                          style: const TextStyle(color: Colors.white70),
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
