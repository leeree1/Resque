import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_packet.dart';
import 'firebase_sync_service.dart';
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

  void _bindRadioService() {
    // Spięcie odbioru radiowego z silnikiem bazy
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

  /// Wywoływane po wciśnięciu SOS na telefonie poszkodowanego
  Future<void> broadcastMySos(SosPacket packet) async {
    _packetStorage[packet.id] = packet;
    _packetsStreamController.add(_packetStorage.values.toList());

    // 1. Zapis na dysku telefonu
    await OfflineStorage.savePacket(packet);

    // 2. Wysłanie w powietrze przez radio Nearby
    await NearbyMeshService().sendPacket(packet);

    // 3. Jeśli mamy internet, pakiet od razu leci do Firebase
    FirebaseSyncService.trySyncInBackground();
  }

  /// Wywoływane automatycznie na telefonie odbiorcy
  Future<void> onPacketReceivedFromPeer(String rawJson) async {
    try {
      final data = jsonDecode(rawJson);
      final packet = SosPacket.fromJson(data);

      if (_packetStorage.containsKey(packet.id)) return;

      packet.hopCount += 1;
      _packetStorage[packet.id] = packet;
      _packetsStreamController.add(_packetStorage.values.toList());

      await OfflineStorage.savePacket(packet);
      debugPrint('SUKCES: Odebrano i zaktualizowano listę pakietów o ${packet.id}');

      // Jeśli ten telefon ma internet, pakiet trafia teraz do Firebase
      FirebaseSyncService.trySyncInBackground();
    } catch (e) {
      debugPrint('Błąd parsowania pakietu: $e');
    }
  }

  /// Wypycha bufor do Firebase (synchronizacja ze sztabem)
  Future<void> flushToCentralServer() async {
    final synced = await FirebaseSyncService.syncLocalQueue();
    if (!synced) return;
    _packetStorage.clear();
    _packetsStreamController.add([]);
    _statusStreamController.add('Zsynchronizowano pakiety z bazą Firebase!');
  }

  List<SosPacket> getAllPackets() => _packetStorage.values.toList();
}