import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_packet.dart';
import 'offline_storage.dart';
import 'nearby_mesh_service.dart';

class MeshNodeService {
  static final MeshNodeService _instance = MeshNodeService._internal();
  factory MeshNodeService() => _instance;

  MeshNodeService._internal() {
    _initStorageAndConnectivity();
    _bindRadioService();
  }

  final Map<String, SosPacket> _packetStorage = {};

  final StreamController<List<SosPacket>> _packetsStreamController =
      StreamController<List<SosPacket>>.broadcast();
  Stream<List<SosPacket>> get packetsStream => _packetsStreamController.stream;

  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusStreamController.stream;

  final StreamController<SosPacket> _ackStreamController =
      StreamController<SosPacket>.broadcast();
  Stream<SosPacket> get ackStream => _ackStreamController.stream;

  void _bindRadioService() {
    NearbyMeshService().bindIncoming((rawJson) {
      onPacketReceivedFromPeer(rawJson);
    });
  }

  Future<void> _initStorageAndConnectivity() async {
    final savedPackets = await OfflineStorage.loadAllPackets();
    for (var packet in savedPackets) {
      _packetStorage[packet.id] = packet;
    }
    _packetsStreamController.add(_packetStorage.values.toList());

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

  Future<void> broadcastMySos(SosPacket packet) async {
    _packetStorage[packet.id] = packet;
    _packetsStreamController.add(_packetStorage.values.toList());
    await OfflineStorage.savePacket(packet);
    await NearbyMeshService().sendPacket(packet);
  }

  Future<void> onPacketReceivedFromPeer(String rawJson) async {
    try {
      final data = jsonDecode(rawJson);
      final packet = SosPacket.fromJson(data);

      if (packet.isAck) {
        debugPrint('ACK OTRZYMANY DLA PAKIETU: ${packet.id}');
        _ackStreamController.add(packet);
        return;
      }

      if (_packetStorage.containsKey(packet.id)) return;

      packet.hopCount += 1;
      _packetStorage[packet.id] = packet;
      _packetsStreamController.add(_packetStorage.values.toList());

      await OfflineStorage.savePacket(packet);
      debugPrint('SUKCES: Odebrano SOS od ${packet.senderName}');

      final ackPacket = SosPacket(
        id: packet.id,
        senderName: 'RATOWNIK_PSP',
        type: packet.type,
        message: 'POTWIERDZONO: Zgłoszenie przyjęte do realizacji',
        timestamp: DateTime.now(),
        isAck: true,
        hopCount: 1,
      );
      await NearbyMeshService().sendPacket(ackPacket);
    } catch (e) {
      debugPrint('Błąd parsowania: $e');
    }
  }

  Future<void> flushToCentralServer() async {
    if (_packetStorage.isEmpty) return;
    await OfflineStorage.clearAll();
    _packetStorage.clear();
    _packetsStreamController.add([]);
    _statusStreamController.add('Zsynchronizowano pakiety ze sztabem!');
  }

  List<SosPacket> getAllPackets() => _packetStorage.values.toList();
}