import 'dart:math';
import 'package:flutter/material.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _simulatedDistance = 24.0; // w metrach
  int _rssi = -78; // dBm

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _simulateGettingCloser() {
    setState(() {
      _simulatedDistance = max(1.5, _simulatedDistance - 5.5);
      _rssi = min(-35, _rssi + 9);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVeryClose = _simulatedDistance < 5.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Radar Sygnału BLE', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.track_changes, color: Colors.cyanAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Wyszukiwanie sygnałów BLE poszkodowanych bez użycia GPS (np. pod gruzami, w piwnicy).',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Container(
                        width: 220 * _animController.value,
                        height: 220 * _animController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(1.0 - _animController.value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isVeryClose ? Colors.redAccent.withOpacity(0.2) : Colors.cyan.withOpacity(0.1),
                      border: Border.all(
                        color: isVeryClose ? Colors.redAccent : Colors.cyanAccent,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_pin_circle,
                            size: 38,
                            color: isVeryClose ? Colors.redAccent : Colors.cyanAccent,
                          ),
                          Text(
                            '${_simulatedDistance.toStringAsFixed(1)} m',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Siła sygnału (RSSI)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('$_rssi dBm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isVeryClose ? Colors.redAccent : Colors.green.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isVeryClose ? 'CEL W ZASIĘGU RĘKI' : 'ZBLIŻASZ SIĘ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _simulateGettingCloser,
                icon: const Icon(Icons.directions_walk, color: Colors.black),
                label: const Text('Symuluj zbliżanie się do poszkodowanego', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}