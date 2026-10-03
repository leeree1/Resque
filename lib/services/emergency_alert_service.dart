import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';

class EmergencyAlertService {
  static final EmergencyAlertService _instance = EmergencyAlertService._internal();
  factory EmergencyAlertService() => _instance;
  EmergencyAlertService._internal();

  bool _isActive = false;
  bool get isActive => _isActive;

  Timer? _strobeTimer;

  // Sekwencja Morse'a dla SOS: 3x kropka (200ms), 3x kreska (600ms), 3x kropka (200ms)
  final List<int> _sosPatternMs = [
    200, 200, 200, 200, 200, 600, // S (... )
    600, 200, 600, 200, 600, 600, // O (--- )
    200, 200, 200, 200, 200, 1200 // S (... )
  ];

  int _step = 0;

  Future<void> startAlarm() async {
    _isActive = true;
    _step = 0;
    _runMorseLoop();
  }

  void _runMorseLoop() async {
    if (!_isActive) return;

    final isLightOn = _step % 2 == 0;
    final duration = _sosPatternMs[_step % _sosPatternMs.length];

    try {
      if (isLightOn) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (e) {
      debugPrint('Latarka niedostępna na tym urządzeniu/przeglądarce: $e');
    }

    _step++;
    _strobeTimer = Timer(Duration(milliseconds: duration), () {
      if (_isActive) _runMorseLoop();
    });
  }

  Future<void> stopAlarm() async {
    _isActive = false;
    _strobeTimer?.cancel();
    _strobeTimer = null;
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }
}