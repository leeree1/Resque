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
  ReportStatus? _selectedFilter;
  bool _isSimulatingInternetGateway = false;

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
        return const Color(0xFFFF2A4B);
      case ReportStatus.confirmed:
        return const Color(0xFFFFB300);
      case ReportStatus.inProgress:
        return const Color(0xFF00E5FF);
      case ReportStatus.resolved:
        return const Color(0xFF00E676);
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

  void _triggerGatewaySimulation() async {
    setState(() => _isSimulatingInternetGateway = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    await MeshNodeService().flushToCentralServer();
    if (!mounted) return;
    setState(() => _isSimulatingInternetGateway = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF00E676),
        content: Row(
          children: [
            Icon(Icons.cloud_done, color: Colors.black),
            SizedBox(width: 10),
            Text(
              'BRAMKA ONLINE: Zsynchronizowano pakiety z Centralnym Serwerem!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 8),
            Text(
              'RESQUE // CENTRUM KOORDYNACJI',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Symuluj połączenie z Internetem (Bramka Ratunkowa)',
            icon: _isSimulatingInternetGateway
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676)))
                : const Icon(Icons.cloud_upload_outlined, color: Color(0xFF00E676)),
            onPressed: _isSimulatingInternetGateway ? null : _triggerGatewaySimulation,
          ),
        ],
      ),
      body: StreamBuilder<List<SosPacket>>(
        stream: MeshNodeService().packetsStream,
        initialData: MeshNodeService().getAllPackets(),
        builder: (context, snapshot) {
          final allPackets = snapshot.data ?? [];
          final filteredPackets = _selectedFilter == null
              ? allPackets
              : allPackets.where((p) => p.status == _selectedFilter).toList();

          final newCount = allPackets.where((p) => p.status == ReportStatus.newReport).length;
          final confirmedCount = allPackets.where((p) => p.status == ReportStatus.confirmed).length;
          final inProgressCount = allPackets.where((p) => p.status == ReportStatus.inProgress).length;
          final resolvedCount = allPackets.where((p) => p.status == ReportStatus.resolved).length;

          return Column(
            children: [
              // Panel Statystyk Zgłoszeń ze Slajdu 07 z możliwością filtrowania
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('NOWE', newCount.toString(), const Color(0xFFFF2A4B), ReportStatus.newReport),
                    _buildStatCol('POTWIERDZONE', confirmedCount.toString(), const Color(0xFFFFB300), ReportStatus.confirmed),
                    _buildStatCol('W TRAKCIE', inProgressCount.toString(), const Color(0xFF00E5FF), ReportStatus.inProgress),
                    _buildStatCol('ROZWIĄZANE', resolvedCount.toString(), const Color(0xFF00E676), ReportStatus.resolved),
                  ],
                ),
              ),

              // Pasek stanu bezpośredniego radia węzłów
              AnimatedBuilder(
                animation: NearbyMeshService(),
                builder: (context, _) {
                  final service = NearbyMeshService();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: service.peersInRange > 0 ? Colors.green.shade900.withOpacity(0.25) : const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: service.peersInRange > 0 ? const Color(0xFF00E676) : const Color(0xFF30363D)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(service.peersInRange > 0 ? Icons.cell_tower : Icons.portable_wifi_off,
                                size: 16, color: service.peersInRange > 0 ? const Color(0xFF00E676) : Colors.white60),
                            const SizedBox(width: 8),
                            Text(
                              service.statusMessage,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: service.peersInRange > 0 ? const Color(0xFF00E676).withOpacity(0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            service.peersInRange > 0 ? 'P2P AKTYWNY' : 'NASŁUCH',
                            style: TextStyle(
                              color: service.peersInRange > 0 ? const Color(0xFF00E676) : Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),

              // Lista zgłoszeń w buforze
              Expanded(
                child: filteredPackets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.leak_remove, color: Colors.white24, size: 36),
                            const SizedBox(height: 10),
                            Text(
                              _selectedFilter != null
                                  ? 'Brak zgłoszeń o statusie ${_statusLabel(_selectedFilter!)}'
                                  : 'Brak zgłoszeń w buforze mesh.\nOczekiwanie na przeskoki w sieci lokalnej...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            if (_selectedFilter != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => setState(() => _selectedFilter = null),
                                child: const Text('POKAŻ WSZYSTKIE', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11)),
                              ),
                            ]
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPackets.length,
                        itemBuilder: (context, index) {
                          final pkt = filteredPackets[index];
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
                              boxShadow: [
                                BoxShadow(
                                  color: _statusColor(pkt.status).withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'SOS #${pkt.id}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF2A4B).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'KRYTYCZNY',
                                            style: TextStyle(color: Color(0xFFFF2A4B), fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                const SizedBox(height: 2),
                                Text(
                                  pkt.message,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 10),

                                // WIZUALIZACJA TRASY MESH (Slajd 03 & Slajd 05)
                                _buildHopProgressVisualizer(hops),
                                const SizedBox(height: 10),

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
                                      'odebrano przez $hops przeskoki',
                                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFFFB300)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          TacticalNavController.switchToSztab();
                                        },
                                        icon: const Icon(Icons.explore, size: 14, color: Color(0xFFFFB300)),
                                        label: const Text('SZTAB / MAPA', style: TextStyle(color: Color(0xFFFFB300), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: _statusColor(pkt.status)),
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
                                              ? 'OZNACZ: ROZWIĄZANE'
                                              : 'POTWIERDŹ I PRZYDZIEL',
                                          style: TextStyle(color: _statusColor(pkt.status), fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildStatCol(String label, String val, Color col, ReportStatus status) {
    final isSelected = _selectedFilter == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? null : status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? col.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? col : Colors.transparent),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? col : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Odzwierciedlenie przepływu ze slajdu 03: TELEFON -> TELEFON -> TELEFON -> BRAMKA
  Widget _buildHopProgressVisualizer(int hops) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHopNode('SOS', true, const Color(0xFFFF2A4B)),
          _buildHopLine(hops >= 1),
          _buildHopNode('WĘZEŁ 1', hops >= 1, const Color(0xFF00E5FF)),
          _buildHopLine(hops >= 2),
          _buildHopNode('WĘZEŁ 2', hops >= 2, const Color(0xFF00E5FF)),
          _buildHopLine(hops >= 3),
          _buildHopNode('BRAMKA', hops >= 3, const Color(0xFF00E676)),
        ],
      ),
    );
  }

  Widget _buildHopNode(String label, bool active, Color col) {
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? col : Colors.white12,
            boxShadow: active ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 4)] : [],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white70 : Colors.white24,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHopLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: active ? const Color(0xFF00E5FF).withOpacity(0.6) : Colors.white10,
      ),
    );
  }
}