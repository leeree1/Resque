import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_packet.dart';
import '../services/emergency_alert_service.dart';
import '../services/mesh_engine.dart';
import '../services/nearby_mesh_service.dart';

class SosBroadcastScreen extends StatefulWidget {
  const SosBroadcastScreen({super.key});

  @override
  State<SosBroadcastScreen> createState() => _SosBroadcastScreenState();
}

class _SosBroadcastScreenState extends State<SosBroadcastScreen>
    with SingleTickerProviderStateMixin {
  EmergencyType _selectedType = EmergencyType.medical;
  bool _isBroadcasting = false;
  bool _isLoadingGps = false;
  SosPacket? _activePacket;

  bool _hasCustomNote = false;
  late final TextEditingController _noteController;

  String _defaultNote(EmergencyType type) => switch (type) {
        EmergencyType.medical => 'Potrzebuję pomocy medycznej.',
        EmergencyType.flood => 'Zagraża mi powódź, potrzebuję pomocy.',
        EmergencyType.trapped => 'Jestem uwięziony/a, potrzebuję pomocy w wydostaniu się.',
        EmergencyType.fire => 'Zagraża mi pożar, potrzebuję pomocy.',
        EmergencyType.other => 'Potrzebuję pomocy.',
      };

  void _selectType(EmergencyType type) {
    setState(() {
      _selectedType = type;
      if (!_hasCustomNote) {
        _noteController.text = _defaultNote(type);
      }
    });
  }

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: _defaultNote(_selectedType));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
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
      id: const Uuid().v4().substring(0, 8),
      senderName: 'WĘZEŁ_ALPHA',
      type: _selectedType,
      message: _noteController.text.trim(),
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      hopCount: 0,
    );

    await MeshNodeService().broadcastMySos(packet);
    EmergencyAlertService().startAlarm();

    setState(() {
      _isLoadingGps = false;
      _isBroadcasting = true;
      _activePacket = packet;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              'RESQUE // TACTICAL SOS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Pasek telemetrii
            _buildTelemetryBar(),
            const SizedBox(height: 16),

            // Przyciski wyboru typu zagrożenia
            const Text(
              'SYGNATURA ZAGROŻENIA:',
              style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            _buildTacticalChips(),
            const SizedBox(height: 16),

            // Pole krótkiego komunikatu
            TextField(
              controller: _noteController,
              onChanged: (_) => _hasCustomNote = true,
              enabled: !_isBroadcasting,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'MELDUNEK TAKTYCZNY',
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Wielki Tactical Przycisk SOS
            _buildBigTacticalButton(),
            const SizedBox(height: 20),

            // Karta dla osób bez aplikacji (Optyczny kod QR)
            if (_isBroadcasting && _activePacket != null) ...[
              _buildQrBroadcastCard(_activePacket!),
              const SizedBox(height: 16),
            ],

            _buildDirectMeshStatusBar(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _telemetryItem(Icons.satellite_outlined, 'GPS OFFLINE', Colors.amberAccent),
          _telemetryItem(Icons.bluetooth_audio, 'BLE MESH', Colors.cyanAccent),
          _telemetryItem(Icons.shield_outlined, 'STORE & FWD', Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _telemetryItem(IconData icon, String text, Color col) {
    return Row(
      children: [
        Icon(icon, size: 15, color: col),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTacticalChips() {
    final types = [
      (EmergencyType.medical, 'MEDYCZNE', Icons.medical_services),
      (EmergencyType.flood, 'POWÓDŹ', Icons.flood),
      (EmergencyType.trapped, 'UWIĘZIENIE', Icons.warning_amber),
      (EmergencyType.fire, 'POŻAR', Icons.local_fire_department),
    ];

    return Row(
      children: types.map((item) {
        final isSelected = _selectedType == item.$1;
        return Expanded(
          child: GestureDetector(
            onTap: _isBroadcasting ? null : () => _selectType(item.$1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF2A4B).withOpacity(0.2) : const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF2A4B) : const Color(0xFF30363D),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(item.$3, size: 16, color: isSelected ? const Color(0xFFFF2A4B) : Colors.white60),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBigTacticalButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoadingGps ? null : _triggerSos,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = _isBroadcasting ? 1.0 + (0.05 * _pulseController.value) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 175,
                height: 175,
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
                      blurRadius: _isBroadcasting ? 30 : 10,
                      spreadRadius: _isBroadcasting ? 8 : 1,
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
                              _isBroadcasting ? Icons.flashlight_on : Icons.crisis_alert,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isBroadcasting ? 'PRZERWIJ' : 'NADAJ SOS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.5,
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
    );
  }

  Widget _buildQrBroadcastCard(SosPacket pkt) {
    final lat = pkt.latitude?.toStringAsFixed(4) ?? 'n/a';
    final lng = pkt.longitude?.toStringAsFixed(4) ?? 'n/a';
    final geoLink = 'geo:$lat,$lng?q=$lat,$lng(SOS+Pomoc)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'OPTYCZNY SYGNAŁ RATUNKOWY (DLA KAMER BEZ APKI)',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(height: 12),
          QrImageView(
            data: geoLink,
            version: QrVersions.auto,
            size: 150.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            'KOORDYNATY: $lat, $lng\nLATARKA NADAJE SOS MORSE\'EM',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
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
          padding: const EdgeInsets.all(14),
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
                  const Icon(Icons.leak_add, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Aktywne węzły BLE: $count',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: count > 0 ? Colors.greenAccent.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count > 0 ? 'M-MESH ONLINE' : 'AUTONOMICZNY',
                  style: TextStyle(
                    color: count > 0 ? Colors.greenAccent : Colors.white38,
                    fontSize: 10,
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
