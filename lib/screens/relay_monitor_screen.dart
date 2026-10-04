import 'package:flutter/material.dart';
import '../main.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';
import '../services/nearby_mesh_service.dart';

class RelayMonitorScreen extends StatefulWidget {
  const RelayMonitorScreen({super.key});

  @override
  State<RelayMonitorScreen> createState() => _RelayMonitorScreenState();
}

class _RelayMonitorScreenState extends State<RelayMonitorScreen> {
  String _labelForType(EmergencyType t) {
    switch (t) {
      case EmergencyType.medical:
        return 'Potrzebna pomoc medyczna';
      case EmergencyType.evacuation:
        return 'Potrzebna ewakuacja';
      case EmergencyType.supplies:
        return 'Potrzebna żywność i woda';
      case EmergencyType.trapped:
        return 'Osoba uwięziona';
      case EmergencyType.other:
        return 'Inne zagrożenie';
    }
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.newReport:
        return Colors.redAccent;
      case ReportStatus.confirmed:
        return Colors.amberAccent;
      case ReportStatus.inProgress:
        return Colors.cyanAccent;
      case ReportStatus.resolved:
        return Colors.greenAccent;
    }
  }

  String _statusLabel(ReportStatus s) {
    switch (s) {
      case ReportStatus.newReport:
        return 'NOWE';
      case ReportStatus.confirmed:
        return 'POTWIERDZONE';
      case ReportStatus.inProgress:
        return 'W TRAKCIE';
      case ReportStatus.resolved:
        return 'ROZWIĄZANE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        title: const Text(
          'RESQUE · RADAR PAKIETÓW',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<SosPacket>>(
        stream: MeshNodeService().packetsStream,
        initialData: MeshNodeService().getAllPackets(),
        builder: (context, snapshot) {
          final packets = snapshot.data ?? [];

          final newCount = packets.where((p) => p.status == ReportStatus.newReport).length;
          final confirmedCount = packets.where((p) => p.status == ReportStatus.confirmed).length;
          final inProgressCount = packets.where((p) => p.status == ReportStatus.inProgress).length;
          final resolvedCount = packets.where((p) => p.status == ReportStatus.resolved).length;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('NOWE', newCount.toString(), Colors.redAccent),
                    _buildStatCol('POTWIERDZONE', confirmedCount.toString(), Colors.amberAccent),
                    _buildStatCol('W TRAKCIE', inProgressCount.toString(), Colors.cyanAccent),
                    _buildStatCol('ROZWIĄZANE', resolvedCount.toString(), Colors.greenAccent),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: NearbyMeshService(),
                builder: (context, _) {
                  final service = NearbyMeshService();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: service.peersInRange > 0 ? Colors.green.shade900.withOpacity(0.3) : const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: service.peersInRange > 0 ? Colors.greenAccent : const Color(0xFF30363D)),
                    ),
                    child: Row(
                      children: [
                        Icon(service.peersInRange > 0 ? Icons.link : Icons.link_off, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.statusMessage,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: packets.isEmpty
                    ? const Center(
                        child: Text(
                          'Brak odebranych zgłoszeń w buforze mesh.\nOczekiwanie na przeskoki...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: packets.length,
                        itemBuilder: (context, index) {
                          final pkt = packets[index];
                          final lat = pkt.latitude?.toStringAsFixed(4) ?? '51.1079';
                          final lng = pkt.longitude?.toStringAsFixed(4) ?? '17.0385';
                          final hops = pkt.hopCount == 0 ? 1 : pkt.hopCount;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _statusColor(pkt.status), width: 1.2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'SOS #${pkt.id}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _statusColor(pkt.status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _statusLabel(pkt.status),
                                        style: TextStyle(color: _statusColor(pkt.status), fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _labelForType(pkt.type),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  pkt.message,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                const Divider(color: Color(0xFF30363D), height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Wrocław · $lat° N, $lng° E',
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                    Text(
                                      'przez $hops przeskoki',
                                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.amberAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          TacticalNavController.switchToSztab();
                                        },
                                        icon: const Icon(Icons.explore, size: 14, color: Colors.amberAccent),
                                        label: const Text('SZTAB / MAPA', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.cyanAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (pkt.status == ReportStatus.newReport) {
                                              pkt.status = ReportStatus.inProgress;
                                            } else if (pkt.status == ReportStatus.inProgress) {
                                              pkt.status = ReportStatus.resolved;
                                            } else {
                                              pkt.status = ReportStatus.newReport;
                                            }
                                          });
                                        },
                                        child: Text(
                                          pkt.status == ReportStatus.inProgress
                                              ? 'ROZWIĄZANE'
                                              : 'POTWIERDŹ',
                                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildStatCol(String label, String val, Color col) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}