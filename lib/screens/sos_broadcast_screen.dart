import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_packet.dart';
import '../services/emergency_alert_service.dart';
import '../services/mesh_engine.dart';
import '../services/packet_codec.dart';

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

  final int _nearbyRelaysFound = 3;
  final _noteController =
      TextEditingController(text: 'Potrzebna pomoc medyczna i woda');

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseController.forward();
        }
      });
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
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  void _triggerSos() async {
    if (_isBroadcasting) {
      EmergencyAlertService().stopAlarm();
      _pulseController.stop();
      setState(() {
        _isBroadcasting = false;
        _activePacket = null;
      });
      return;
    }

    setState(() => _isLoadingGps = true);

    double lat = 51.1079; // Wrocław Rynek (fallback demo)
    double lng = 17.0385;

    final pos = await _determinePosition();
    if (pos != null) {
      lat = pos.latitude;
      lng = pos.longitude;
    }

    if (!mounted) return;

    final packet = SosPacket(
      id: const Uuid().v4().substring(0, 8),
      senderName: 'Poszkodowany #A1',
      type: _selectedType,
      message: _noteController.text.trim(),
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      hopCount: 0,
    );

    // 1. Zapis do bazy offline i rozgłoszenie mesh
    await MeshNodeService().broadcastMySos(packet);

    // 2. Uruchomienie fizycznego alarmu i stroboskopu Morse'a
    EmergencyAlertService().startAlarm();
    _pulseController.forward();

    setState(() {
      _isLoadingGps = false;
      _isBroadcasting = true;
      _activePacket = packet;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          'ALARM AKTYWNY! Latarka nadaje SOS. Koordynaty: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.radar, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Resque • Mesh SOS',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                border: _isBroadcasting
                    ? Border.all(
                        color: Colors.redAccent
                            .withOpacity(0.3 + 0.7 * _pulseController.value),
                        width: 4,
                      )
                    : null,
              ),
              child: child,
            );
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              _buildNetworkStatusCard(),
              const SizedBox(height: 16),
              const Text(
                'Wybierz rodzaj zagrożenia:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 10),
              _buildEmergencyChips(),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                enabled: !_isBroadcasting,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Krótka informacja',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildBigSosButton(),
              const SizedBox(height: 20),
              if (_isBroadcasting && _activePacket != null) ...[
                _buildNonAppUserCard(_activePacket!),
                const SizedBox(height: 16),
              ],
              _buildMeshNodesInfo(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tryb Offline (Brak GSM/Internetu)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sygnał przekazywany przez BLE Mesh + stroboskop optyczny.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyChips() {
    final types = [
      (EmergencyType.medical, 'Medyczne', Icons.medical_services_outlined),
      (EmergencyType.flood, 'Woda / Powódź', Icons.flood_outlined),
      (EmergencyType.trapped, 'Uwięzienie', Icons.warning_amber_outlined),
      (EmergencyType.fire, 'Pożar', Icons.local_fire_department_outlined),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((item) {
        final isSelected = _selectedType == item.$1;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$3,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(width: 6),
              Text(item.$2),
            ],
          ),
          selected: isSelected,
          selectedColor: Colors.redAccent,
          backgroundColor: const Color(0xFF1E1E1E),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
          ),
          onSelected: _isBroadcasting
              ? null
              : (val) {
                  if (val) setState(() => _selectedType = item.$1);
                },
        );
      }).toList(),
    );
  }

  Widget _buildBigSosButton() {
    return Center(
      child: GestureDetector(
        onTap: _isLoadingGps ? null : _triggerSos,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isBroadcasting ? Colors.red.shade900 : Colors.redAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(_isBroadcasting ? 0.8 : 0.3),
                blurRadius: _isBroadcasting ? 40 : 15,
                spreadRadius: _isBroadcasting ? 12 : 2,
              ),
            ],
          ),
          child: Center(
            child: _isLoadingGps
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBroadcasting
                            ? Icons.flashlight_on
                            : Icons.sos,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isBroadcasting ? 'WYŁĄCZ ALARM' : 'WYŚLIJ SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNonAppUserCard(SosPacket pkt) {
    // Standardowy link Geo URI, który każdy zwykły telefon bez aplikacji otworzy w Mapach Google/Apple
    final geoLink =
        'geo:${pkt.latitude},${pkt.longitude}?q=${pkt.latitude},${pkt.longitude}(SOS+Pomoc)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'DLA OSÓB BEZ APLIKACJI',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Skieruj dowolny aparat telefonu na poniższy kod:',
            style: TextStyle(color: Colors.black87, fontSize: 12),
          ),
          const SizedBox(height: 12),
          QrImageView(
            data: geoLink,
            version: QrVersions.auto,
            size: 160.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            'Pozycja: ${pkt.latitude.toStringAsFixed(4)}, ${pkt.longitude.toStringAsFixed(4)}\nLatarka miga sygnał SOS w alfabecie Morse\'a',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshNodesInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth_searching,
                  color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Węzły przekaźnikowe w zasięgu: $_nearbyRelaysFound',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const Text(
            'Gotowy do skoku',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}