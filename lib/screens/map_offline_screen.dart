import 'package:flutter/material.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';
import '../services/nearby_mesh_service.dart';

class MapOfflineScreen extends StatelessWidget {
  const MapOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.satellite_alt_outlined, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              'TAKTYCZNY SZTAB MESH',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<SosPacket>>(
        stream: MeshNodeService().packetsStream,
        initialData: MeshNodeService().getAllPackets(),
        builder: (context, snapshot) {
          final packets = snapshot.data ?? [];

          return Column(
            children: [
              // Taktyczny HUD siatki współrzędnych
              Container(
                margin: const EdgeInsets.all(16),
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                ),
                child: Stack(
                  children: [
                    // Linie celownika / radaru siatki
                    Center(
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 1.5),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amberAccent.withOpacity(0.3), width: 1.5),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.my_location, color: Colors.cyanAccent, size: 28),
                    ),
                    // Rozmieszczone punkty zagrożeń z bufora
                    ...packets.map((p) {
                      return Positioned(
                        left: 40.0 + ((p.id.hashCode % 140)),
                        top: 30.0 + (((p.id.hashCode ~/ 3) % 130)),
                        child: Tooltip(
                          message: '${p.senderName}: ${p.message}',
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF2A4B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.warning_amber, size: 14, color: Colors.white),
                              ),
                              Text(
                                p.id,
                                style: const TextStyle(fontSize: 9, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: Text(
                        'SEKTOR: DOLNY ŚLĄSK • AKTYWNYCH CELÓW: ${packets.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista odebranych celów do ewakuacji
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SEKTORY ZGŁOSZEŃ',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Direct Nodes: ${NearbyMeshService().peersInRange}',
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: packets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.explore_off, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            const Text('Brak zgłoszeń w buforze sektorowym', style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: packets.length,
                        itemBuilder: (context, index) {
                          final p = packets[index];
                          final lat = p.latitude?.toStringAsFixed(4) ?? 'n/a';
                          final lng = p.longitude?.toStringAsFixed(4) ?? 'n/a';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF30363D)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2A4B).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.location_on, color: Color(0xFFFF2A4B)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.senderName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'GPS: $lat, $lng',
                                        style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                                      ),
                                      Text(
                                        p.message,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.cyanAccent),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'SKOK ${p.hopCount}',
                                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}