import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/sos_packet.dart';
import '../services/emergency_alert_service.dart';
import '../services/mesh_engine.dart';
import '../services/nearby_mesh_service.dart';

class SosBroadcastScreen extends StatefulWidget {
  const SosBroadcastScreen({super.key});

  static String? customNote;
  static EmergencyType? customType;

  @override
  State<SosBroadcastScreen> createState() => _SosBroadcastScreenState();
}

class _SosBroadcastScreenState extends State<SosBroadcastScreen>
    with SingleTickerProviderStateMixin {
  EmergencyType _selectedType = EmergencyType.trapped;
  bool _isBroadcasting = false;
  bool _isLoadingGps = false;
  bool _stealthMode = false;
  bool _isAckReceived = false;
  int _victimsCount = 2;
  String _selectedBlood = 'A+';
  SosPacket? _activePacket;

  StreamSubscription? _ackSub;

  final _noteController = TextEditingController(
    text: '2 osoby uwięzione. Potrzebujemy ewakuacji.',
  );

  late AnimationController _pulseController;

  String _defaultNote(EmergencyType type) => switch (type) {
        EmergencyType.medical => 'Potrzebna natychmiastowa pomoc medyczna.',
        EmergencyType.evacuation => 'Wymagana ewakuacja z zalanego budynku.',
        EmergencyType.supplies => 'Brak wody pitnej i żywności.',
        EmergencyType.trapped => '2 osoby uwięzione. Potrzebujemy ewakuacji.',
        EmergencyType.other => 'Zagrożenie życia, prosimy o kontakt ze sztabem.',
      };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _ackSub = MeshNodeService().ackStream.listen((ack) {
      if (_isBroadcasting && _activePacket != null && ack.id == _activePacket!.id) {
        setState(() {
          _isAckReceived = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _ackSub?.cancel();
    _pulseController.dispose();
    _noteController.dispose();
    EmergencyAlertService().stopAlarm();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
  }

  void _triggerSos() async {
    if (_isBroadcasting) {
      EmergencyAlertService().stopAlarm();
      setState(() {
        _isBroadcasting = false;
        _isAckReceived = false;
        _activePacket = null;
      });
      return;
    }

    setState(() => _isLoadingGps = true);

    double lat = 51.1079;
    double lng = 17.0385;

    final pos = await _determinePosition();
    if (pos != null) {
      lat = pos.latitude;
      lng = pos.longitude;
    }

    if (!mounted) return;

    final packet = SosPacket(
      id: '1842',
      senderName: 'POSZKODOWANY_01',
      type: _selectedType,
      message: _noteController.text.trim(),
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      hopCount: 0,
      bloodType: _selectedBlood,
      victimsCount: _victimsCount,
    );

    await MeshNodeService().broadcastMySos(packet);

    if (!_stealthMode) {
      EmergencyAlertService().startAlarm();
    }

    setState(() {
      _isLoadingGps = false;
      _isBroadcasting = true;
      _isAckReceived = false;
      _activePacket = packet;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (SosBroadcastScreen.customNote != null) {
      _noteController.text = SosBroadcastScreen.customNote!;
      if (SosBroadcastScreen.customType != null) {
        _selectedType = SosBroadcastScreen.customType!;
      }
      SosBroadcastScreen.customNote = null;
      SosBroadcastScreen.customType = null;
    }

    if (_stealthMode && _isBroadcasting) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: InkWell(
          onTap: () => setState(() => _stealthMode = false),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_moon, color: Colors.white24, size: 40),
                SizedBox(height: 12),
                Text(
                  'TRYB CZARNY (STEALTH MESH AKTYWNY)\nDotknij ekranu, aby przywrócić interfejs',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isBroadcasting ? Colors.redAccent : Colors.greenAccent,
                boxShadow: [
                  BoxShadow(
                    color: _isBroadcasting ? Colors.redAccent : Colors.greenAccent,
                    blurRadius: 6,
                  )
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'RESQUE // TRYB OFFLINE · MESH',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tryb Cichy / Stealth',
            icon: Icon(
              _stealthMode ? Icons.visibility_off : Icons.visibility,
              color: _stealthMode ? Colors.amberAccent : Colors.white60,
            ),
            onPressed: () {
              setState(() => _stealthMode = !_stealthMode);
              if (_stealthMode && _isBroadcasting) {
                EmergencyAlertService().stopAlarm();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            if (_isAckReceived) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent, width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ZGŁOSZENIE #1842 PRZYJĘTE',
                              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('ZESPÓŁ RATUNKOWY W TRAKCIE · POMOC W DRODZE',
                              style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _buildAutoMetadataBar(),
            const SizedBox(height: 12),
            const Text(
              'CZEGO POTRZEBUJESZ?',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            _buildNeedChips(),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !_isBroadcasting,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'MELDUNEK TAKTYCZNY',
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF30363D))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF30363D))),
              ),
            ),
            const SizedBox(height: 16),
            _buildBigTacticalButton(),
            const SizedBox(height: 16),
            if (_isBroadcasting && _activePacket != null) ...[
              _buildQrBroadcastCard(_activePacket!),
              const SizedBox(height: 14),
            ],
            _buildDirectMeshStatusBar(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoMetadataBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AUTOMATYCZNIE DODAWANE DO PAKIETU:',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('LOKALIZACJA: 51.1079° N, 17.0385° E', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('PRIORYTET: KRYTYCZNY', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeedChips() {
    final types = [
      (EmergencyType.medical, 'POMOC MEDYCZNA', Icons.medical_services),
      (EmergencyType.evacuation, 'EWAKUACJA', Icons.directions_run),
      (EmergencyType.supplies, 'ŻYWNOŚĆ / WODA', Icons.water_drop),
      (EmergencyType.trapped, 'JESTEM UWIĘZIONY', Icons.warning_amber),
      (EmergencyType.other, 'INNE', Icons.more_horiz),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.map((item) {
        final isSelected = _selectedType == item.$1;
        return GestureDetector(
          onTap: _isBroadcasting
              ? null
              : () {
                  setState(() {
                    _selectedType = item.$1;
                    _noteController.text = _defaultNote(item.$1);
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF2A4B).withOpacity(0.2) : const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFFFF2A4B) : const Color(0xFF30363D),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$3, size: 14, color: isSelected ? const Color(0xFFFF2A4B) : Colors.white60),
                const SizedBox(width: 6),
                Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBigTacticalButton() {
    return Column(
      children: [
        GestureDetector(
          onLongPress: _isLoadingGps ? null : _triggerSos,
          onTap: _isBroadcasting ? _triggerSos : null,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _isBroadcasting ? 1.0 + (0.04 * _pulseController.value) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 155,
                  height: 155,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isBroadcasting ? const Color(0xFFFF2A4B) : const Color(0xFF1F242C),
                    border: Border.all(
                      color: _isBroadcasting ? Colors.white : const Color(0xFFFF2A4B),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2A4B).withOpacity(_isBroadcasting ? 0.6 : 0.2),
                        blurRadius: _isBroadcasting ? 26 : 8,
                        spreadRadius: _isBroadcasting ? 6 : 1,
                      )
                    ],
                  ),
                  child: Center(
                    child: _isLoadingGps
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isBroadcasting ? Icons.radar : Icons.crisis_alert,
                                size: 40,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isBroadcasting ? 'PRZERWIJ' : 'SOS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isBroadcasting ? 'NADAWANIE W SIECI MESH...' : 'przytrzymaj, aby wysłać',
          style: TextStyle(
            color: _isBroadcasting ? Colors.redAccent : Colors.white38,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildQrBroadcastCard(SosPacket pkt) {
    final lat = pkt.latitude?.toStringAsFixed(4) ?? 'n/a';
    final lng = pkt.longitude?.toStringAsFixed(4) ?? 'n/a';
    final geoLink = 'geo:$lat,$lng?q=$lat,$lng(SOS+Resque+#${pkt.id})';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'OPTYCZNY SYGNAŁ RATUNKOWY (DLA DRONÓW I SŁUŻB)',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          const SizedBox(height: 8),
          QrImageView(
            data: geoLink,
            version: QrVersions.auto,
            size: 130.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            'ID: #${pkt.id} · WROCŁAW · $lat, $lng',
            style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectMeshStatusBar() {
    return AnimatedBuilder(
      animation: NearbyMeshService(),
      builder: (context, _) {
        final service = NearbyMeshService();
        final count = service.peersInRange;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.leak_add, color: Colors.cyanAccent, size: 16),
                  const SizedBox(width: 8),
                  Text('Węzły w zasięgu bezpośrednim: $count', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: count > 0 ? Colors.greenAccent.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count > 0 ? 'MESH LINK OK' : 'AUTONOMICZNY',
                  style: TextStyle(
                    color: count > 0 ? Colors.greenAccent : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
