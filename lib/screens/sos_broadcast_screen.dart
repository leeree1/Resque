import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_packet.dart';
import '../services/mesh_engine.dart';

class SosBroadcastScreen extends StatefulWidget {
  const SosBroadcastScreen({super.key});

  @override
  State<SosBroadcastScreen> createState() => _SosBroadcastScreenState();
}

class _SosBroadcastScreenState extends State<SosBroadcastScreen> {
  EmergencyType _selectedType = EmergencyType.medical;
  bool _isBroadcasting = false;
  bool _isLoadingGps = false;
  final int _nearbyRelaysFound = 3;
  final _noteController = TextEditingController(text: 'Potrzebna pomoc medyczna i woda');

  @override
  void dispose() {
    _noteController.dispose();
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
      setState(() => _isBroadcasting = false);
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

    setState(() {
      _isLoadingGps = false;
      _isBroadcasting = true;
    });

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

    MeshNodeService().broadcastMySos(packet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('Sygnał SOS rozsyłany w sieci Mesh! GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
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
            Text('Resque • Mesh SOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNetworkStatusCard(),
              const SizedBox(height: 24),
              const Text(
                'Wybierz rodzaj zagrożenia:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildEmergencyChips(),
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Krótka informacja',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const Spacer(),
              _buildBigSosButton(),
              const Spacer(),
              _buildMeshNodesInfo(),
              const SizedBox(height: 16),
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
                Text('Tryb Offline (Brak GSM/Internetu)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Sygnał zostanie przekazany skokowo przez telefony w zasięgu BLE.', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
              Icon(item.$3, size: 16, color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(width: 6),
              Text(item.$2),
            ],
          ),
          selected: isSelected,
          selectedColor: Colors.redAccent,
          backgroundColor: const Color(0xFF1E1E1E),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
          onSelected: (val) {
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
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isBroadcasting ? Colors.red.shade900 : Colors.redAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(_isBroadcasting ? 0.7 : 0.3),
                blurRadius: _isBroadcasting ? 35 : 15,
                spreadRadius: _isBroadcasting ? 10 : 2,
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
                        _isBroadcasting ? Icons.broadcast_on_personal : Icons.sos,
                        size: 54,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isBroadcasting ? 'NADAWANIE...' : 'WYŚLIJ SOS',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ],
                  ),
          ),
        ),
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
              const Icon(Icons.bluetooth_searching, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text('Pobliskie węzły przekaźnikowe: $_nearbyRelaysFound', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const Text('Gotowy do skoku', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}