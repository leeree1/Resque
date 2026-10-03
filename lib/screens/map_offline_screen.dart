import 'package:flutter/material.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';

enum SafePointType { evacuation, fireStation, medical, shelter }

class TacticalSafePoint {
  final String id;
  final String name;
  final String address;
  final SafePointType type;
  final double latitude;
  final double longitude;
  final double radarDx; // Pozycja na radarze HUD
  final double radarDy;
  final String capacity;
  final bool isOpen;

  const TacticalSafePoint({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.radarDx,
    required this.radarDy,
    required this.capacity,
    this.isOpen = true,
  });

  IconData get icon {
    switch (type) {
      case SafePointType.evacuation:
        return Icons.directions_run;
      case SafePointType.fireStation:
        return Icons.local_fire_department;
      case SafePointType.medical:
        return Icons.local_hospital;
      case SafePointType.shelter:
        return Icons.shield;
    }
  }

  Color get color {
    switch (type) {
      case SafePointType.evacuation:
        return const Color(0xFF00E5FF); // Cyjan
      case SafePointType.fireStation:
        return const Color(0xFFFF9100); // Pomarańcz
      case SafePointType.medical:
        return const Color(0xFF00E676); // Zielony
      case SafePointType.shelter:
        return const Color(0xFF7C4DFF); // Fiolet
    }
  }

  String get typeLabel {
    switch (type) {
      case SafePointType.evacuation:
        return 'PUNKT EWAKUACJI';
      case SafePointType.fireStation:
        return 'STRAŻ POŻARNA';
      case SafePointType.medical:
        return 'PUNKT OPATRUNKOWY';
      case SafePointType.shelter:
        return 'SCHRON OBRONY CYWILNEJ';
    }
  }
}

class MapOfflineScreen extends StatefulWidget {
  const MapOfflineScreen({super.key});

  @override
  State<MapOfflineScreen> createState() => _MapOfflineScreenState();
}

class _MapOfflineScreenState extends State<MapOfflineScreen> {
  int _tabIndex = 0; // 0 - Punkty bezpieczne, 1 - Zgłoszenia SOS

  // Stała baza punktów awaryjnych (współrzędne lokalne)
  final List<TacticalSafePoint> _safePoints = const [
    TacticalSafePoint(
      id: 'EVAC-01',
      name: 'Główny Punkt Zborny Stadion',
      address: 'Sektor Północny, Wyższa Trybuna',
      type: SafePointType.evacuation,
      latitude: 50.0710,
      longitude: 19.9880,
      radarDx: 65,
      radarDy: 45,
      capacity: 'Pojemność: 800 osób (Czysta woda, koce)',
    ),
    TacticalSafePoint(
      id: 'PSP-04',
      name: 'Jednostka Ratowniczo-Gaśnicza PSP',
      address: 'ul. Przemysłowa 12',
      type: SafePointType.fireStation,
      latitude: 50.0620,
      longitude: 19.9950,
      radarDx: 215,
      radarDy: 60,
      capacity: 'Sprzęt: Łodzie motorowe, amfibie',
    ),
    TacticalSafePoint(
      id: 'MED-02',
      name: 'Szpital Polowy / Punkt Triage',
      address: 'Liceum Ogólnokształcące nr 3',
      type: SafePointType.medical,
      latitude: 50.0695,
      longitude: 20.0010,
      radarDx: 230,
      radarDy: 155,
      capacity: 'Lekarz dyżurny, tlenoterapia',
    ),
    TacticalSafePoint(
      id: 'BUNK-09',
      name: 'Schron Podziemny OC nr 4',
      address: 'Kompleks Sportowy, Poziom -2',
      type: SafePointType.shelter,
      latitude: 50.0600,
      longitude: 19.9820,
      radarDx: 75,
      radarDy: 160,
      capacity: 'Filtrowentylacja, zasilanie agregatem',
    ),
  ];

  void _showGuidanceDialog(TacticalSafePoint pt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: pt.color, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(pt.icon, color: pt.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pt.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TYP: ${pt.typeLabel}',
              style: TextStyle(
                color: pt.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Lokalizacja: ${pt.address}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              pt.capacity,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0F12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.explore, color: Colors.cyanAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AZYMUT MARSZU OFFLINE',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Kierunek: 035° (Północny-Wschód)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Szacowany dystans: ok. 850 metrów',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ZAMKNIJ',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.satellite_alt_outlined,
              color: Colors.amberAccent,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'TAKTYCZNY SZTAB MESH',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
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
              // Taktyczny HUD Radaru z punktami SOS i stałymi bazami
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Kręgi celownika
                      Center(
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white10,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.amberAccent.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.my_location,
                          color: Colors.cyanAccent,
                          size: 26,
                        ),
                      ),

                      // Punkty Bezpieczne (Bazy / Szpitale / Straż / Ewakuacja)
                      ..._safePoints.map((pt) {
                        return Positioned(
                          left: pt.radarDx,
                          top: pt.radarDy,
                          child: GestureDetector(
                            onTap: () => _showGuidanceDialog(pt),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: pt.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: pt.color.withOpacity(0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    pt.icon,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    pt.id,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: pt.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Punkty Celów SOS z powietrza
                      ...packets.map((p) {
                        return Positioned(
                          left: 60.0 + ((p.id.hashCode.abs() % 130)),
                          top: 40.0 + (((p.id.hashCode.abs() ~/ 4) % 120)),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF2A4B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                p.id,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      Positioned(
                        bottom: 8,
                        left: 12,
                        child: Text(
                          'PUNKTY BEZPIECZNE: ${_safePoints.length} • AKTYWNE SOS: ${packets.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Przełącznik zakładek (Bezpieczne bazy vs Zgłoszenia SOS)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0
                                ? Colors.cyanAccent.withOpacity(0.15)
                                : const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _tabIndex == 0
                                  ? Colors.cyanAccent
                                  : const Color(0xFF30363D),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'PUNKTY EWAKUACJI (${_safePoints.length})',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _tabIndex == 0
                                    ? Colors.cyanAccent
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1
                                ? const Color(0xFFFF2A4B).withOpacity(0.15)
                                : const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _tabIndex == 1
                                  ? const Color(0xFFFF2A4B)
                                  : const Color(0xFF30363D),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'ODEBRANE SOS (${packets.length})',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _tabIndex == 1
                                    ? const Color(0xFFFF2A4B)
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Zawartość listy
              Expanded(
                child: _tabIndex == 0
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _safePoints.length,
                        itemBuilder: (context, index) {
                          final pt = _safePoints[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF30363D),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: pt.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    pt.icon,
                                    color: pt.color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pt.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        pt.address,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pt.capacity,
                                        style: TextStyle(
                                          color: pt.color,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showGuidanceDialog(pt),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pt.color.withOpacity(0.2),
                                    foregroundColor: pt.color,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: pt.color),
                                    ),
                                  ),
                                  icon: const Icon(Icons.navigation, size: 14),
                                  label: const Text(
                                    'PROWADŹ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : packets.isEmpty
                    ? const Center(
                        child: Text(
                          'Brak odebranych celów SOS w buforze',
                          style: TextStyle(color: Colors.white38),
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
                              border: Border.all(
                                color: const Color(0xFFFF2A4B).withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF2A4B,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFFFF2A4B),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.senderName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'GPS: $lat, $lng',
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        p.message,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.cyanAccent,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'SKOK ${p.hopCount}',
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                    ),
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
