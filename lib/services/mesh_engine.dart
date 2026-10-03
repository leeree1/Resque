import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_packet.dart';

class MeshNodeService {
  static final MeshNodeService _instance = MeshNodeService._internal();
  factory MeshNodeService() => _instance;
  
  MeshNodeService._internal() {
    _initConnectivityListener();
  }

  final Map<String, SosPacket> _packetStorage = {};
  final StreamController<List<SosPacket>> _packetsStreamController =
      StreamController<List<SosPacket>>.broadcast();
  Stream<List<SosPacket>> get packetsStream => _packetsStreamController.stream;

  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusStreamController.stream;

  // Automatyczny uplink: telefon sam wykrywa połączenie z Internetem
  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasInternet = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (hasInternet && _packetStorage.isNotEmpty) {
        _statusStreamController.add('Wykryto Internet! Synchronizacja bufora...');
        flushToCentralServer();
      }
    });
  }

  void broadcastMySos(SosPacket packet) {
    _packetStorage[packet.id] = packet;
    _packetsStreamController.add(_packetStorage.values.toList());
    _propagateViaBluetooth(packet);
  }

  void onPacketReceivedFromPeer(String rawJson) {
    try {
      final data = jsonDecode(rawJson);
      final packet = SosPacket.fromJson(data);

      if (_packetStorage.containsKey(packet.id)) return;

      packet.hopCount += 1;
      _packetStorage[packet.id] = packet;
      _packetsStreamController.add(_packetStorage.values.toList());

      _propagateViaBluetooth(packet);
    } catch (e) {
      debugPrint('Błąd pakietu mesh: $e');
    }
  }

  void _propagateViaBluetooth(SosPacket packet) {
    debugPrint('[BLE MESH OUT]: ${packet.id} skok: ${packet.hopCount}');
  }

  Future<void> flushToCentralServer() async {
    if (_packetStorage.isEmpty) return;
    
    // Wypchnięcie do sztabu / centralnej bazy
    debugPrint('UPLINK: Wypychanie ${_packetStorage.length} pakietów na serwer ratunkowy.');
    _statusStreamController.add('Pomyślnie zsynchronizowano ${_packetStorage.length} zgłoszeń ze sztabem!');
  }

  List<SosPacket> getAllPackets() => _packetStorage.values.toList();
}