import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';

enum SafePointType { evacuation, fireStation, medical, shelter }

class TacticalSafePoint {
  final String id;
  final String name;
  final String address;
  final SafePointType type;
  final LatLng point;
  final String capacity;

  const TacticalSafePoint({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.point,
    required this.capacity,
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
        return const Color(0xFF00E5FF);
      case SafePointType.fireStation:
        return const Color(0xFFFF9100);
      case SafePointType.medical:
        return const Color(0xFF00E676);
      case SafePointType.shelter:
        return const Color(0xFF7C4DFF);
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

class _MapOfflineScreenState extends State<MapOfflineScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentMapCenter = const LatLng(51.1079, 17.0385);
  LatLng? _userPosition;
  bool _isLocating = true;
  String _locationStatus = 'Inicjalizacja GPS...';
  int _tabIndex = 0;
  StreamSubscription<Position>? _positionStreamSub;
  late AnimationController _pulseController;

  final List<TacticalSafePoint> _safePoints = const [
    TacticalSafePoint(
      id: 'EVAC-01',
      name: 'Główny Punkt Zborny Stadion',
      address: 'al. Śląska 1',
      type: SafePointType.evacuation,
      point: LatLng(51.1415, 16.9427),
      capacity: 'Pojemność: 800 osób (Czysta woda, koce)',
    ),
    TacticalSafePoint(
      id: 'PSP-04',
      name: 'Jednostka Ratowniczo-Gaśnicza PSP',
      address: 'ul. Borowska 138',
      type: SafePointType.fireStation,
      point: LatLng(51.0886, 17.0375),
      capacity: 'Sprzęt: Łodzie motorowe, amfibie',
    ),
    TacticalSafePoint(
      id: 'MED-02',
      name: 'Szpital Polowy / Punkt Triage',
      address: 'ul. Traugutta 116',
      type: SafePointType.medical,
      point: LatLng(51.1038, 17.0543),
      capacity: 'Lekarz dyżurny, tlenoterapia',
    ),
    TacticalSafePoint(
      id: 'BUNK-09',
      name: 'Schron Podziemny OC nr 4',
      address: 'pl. Nowy Targ / Solny',
      type: SafePointType.shelter,
      point: LatLng(51.1098, 17.0360),
      capacity: 'Filtrowentylacja, zasilanie agregatem',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    setState(() {
      _isLocating = true;
      _locationStatus = 'Pobieranie pozycji z przeglądarki...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationStatus = 'Lokalizacja wyłączona w systemie';
          _userPosition = const LatLng(51.1079, 17.0385);
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _locationStatus = 'Brak uprawnień. Zezwól w przeglądarce!';
          _userPosition = const LatLng(51.1079, 17.0385);
        });
        return;
      }

      // Bezpośrednie wymuszenie pozycji z przeglądarki/telefonu
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final newPos = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() {
        _userPosition = newPos;
        _currentMapCenter = newPos;
        _isLocating = false;
        _locationStatus =
            '${pos.latitude.toStringAsFixed(4)}° N, ${pos.longitude.toStringAsFixed(4)}° E';
      });

      _mapController.move(newPos, 14.5);

      // Strumień na żywo
      _positionStreamSub?.cancel();
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
        ),
      ).listen(
        (Position livePos) {
          if (!mounted) return;
          final updatedPos = LatLng(livePos.latitude, livePos.longitude);
          setState(() {
            _userPosition = updatedPos;
            _locationStatus =
                '${livePos.latitude.toStringAsFixed(4)}° N, ${livePos.longitude.toStringAsFixed(4)}° E';
          });
        },
        onError: (e) {
          debugPrint('Błąd streamu lokalizacji: $e');
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationStatus = 'Użyto domyślnych (Wrocław)';
        _userPosition = const LatLng(51.1079, 17.0385);
      });
      debugPrint('Wyjątek geolokalizacji: $e');
    }
  }

  void _recenterOnUser() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 15.0);
    } else {
      _initLocationTracking();
    }
  }

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
                    fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TYP: ${pt.typeLabel}',
                style: TextStyle(
                    color: pt.color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Lokalizacja: ${pt.address}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(pt.capacity,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0F12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: Colors.cyanAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AZYMUT MARSZU OFFLINE',
                            style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        Text(
                            'Koordynaty: ${pt.point.latitude.toStringAsFixed(4)}, ${pt.point.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        const Text('Nawigacja bezpośrednia w siatce OpenStreetMap',
                            style: TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (pt.type == SafePointType.medical)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                TacticalNavController.switchToApteczka();
              },
              icon: const Icon(Icons.medical_services,
                  size: 14, color: Colors.redAccent),
              label: const Text('OTWÓRZ APTECZKĘ',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ZAMKNIJ', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePin = _userPosition ?? _currentMapCenter;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.map_outlined, color: Colors.amberAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'TAKTYCZNA MAPA SZTABU',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Namierz mnie',
            icon: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.cyanAccent))
                : const Icon(Icons.my_location, color: Colors.cyanAccent),
            onPressed: _recenterOnUser,
          ),
        ],
      ),
      body: StreamBuilder<List<SosPacket>>(
        stream: MeshNodeService().packetsStream,
        initialData: MeshNodeService().getAllPackets(),
        builder: (context, snapshot) {
          final packets = snapshot.data ?? [];

          final markers = <Marker>[
            // Marker pozycji użytkownika
            Marker(
              point: activePin,
              width: 60,
              height: 60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 38 + (18 * _pulseController.value),
                        height: 38 + (18 * _pulseController.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF)
                              .withOpacity(0.3 * (1.0 - _pulseController.value)),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0xFF00E5FF),
                                blurRadius: 8,
                                spreadRadius: 1),
                          ],
                        ),
                        child: const Icon(Icons.navigation,
                            color: Colors.black, size: 14),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Punkty bezpieczne
            ..._safePoints.map((pt) {
              return Marker(
                point: pt.point,
                width: 50,
                height: 50,
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
                                color: pt.color.withOpacity(0.6), blurRadius: 6)
                          ],
                        ),
                        child: Icon(pt.icon, size: 14, color: Colors.black),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          pt.id,
                          style: TextStyle(
                              fontSize: 8,
                              color: pt.color,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Zgłoszenia SOS
            ...packets.map((pkt) {
              final lat = pkt.latitude ?? 51.1079;
              final lng = pkt.longitude ?? 17.0385;
              return Marker(
                point: LatLng(lat, lng),
                width: 50,
                height: 50,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF2A4B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xFFFF2A4B), blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Icons.crisis_alert,
                          size: 14, color: Colors.white),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFFF2A4B)),
                      ),
                      child: Text(
                        '#${pkt.id}',
                        style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ];

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: activePin,
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.resque',
                          ),
                          MarkerLayer(markers: markers),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0F12).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _userPosition != null
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _locationStatus,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              const SizedBox(height: 6),
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
                              border: Border.all(color: const Color(0xFF30363D)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: pt.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(pt.icon, color: pt.color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(pt.name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      Text(pt.address,
                                          style: const TextStyle(
                                              color: Colors.white54, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(pt.capacity,
                                          style: TextStyle(
                                              color: pt.color, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _mapController.move(pt.point, 15.0);
                                    _showGuidanceDialog(pt);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pt.color.withOpacity(0.2),
                                    foregroundColor: pt.color,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: pt.color),
                                    ),
                                  ),
                                  icon: const Icon(Icons.navigation, size: 14),
                                  label: const Text('PROWADŹ',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : packets.isEmpty
                        ? const Center(
                            child: Text(
                              'Brak odebranych zgłoszeń SOS w buforze mesh',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: packets.length,
                            itemBuilder: (context, index) {
                              final p = packets[index];
                              final lat = p.latitude ?? 51.1079;
                              final lng = p.longitude ?? 17.0385;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161B22),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFF2A4B)
                                          .withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF2A4B)
                                          .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.location_on,
                                          color: Color(0xFFFF2A4B)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('SOS #${p.id} · ${p.senderName}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                              'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                                              style: const TextStyle(
                                                  color: Colors.amberAccent,
                                                  fontSize: 11)),
                                          Text(p.message,
                                              style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _mapController.move(
                                            LatLng(lat, lng), 15.5);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF2A4B)
                                            .withOpacity(0.2),
                                        foregroundColor: const Color(0xFFFF2A4B),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                      child: const Text('NAMIERZ',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
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