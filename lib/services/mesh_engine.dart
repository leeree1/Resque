import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/sos_packet.dart';
import 'nearby_mesh_service.dart';
import 'offline_storage.dart';

class MeshNodeService {
  static final MeshNodeService _instance = MeshNodeService._internal();
  factory MeshNodeService() => _instance;

  MeshNodeService._internal() {
    final link = NearbyMeshService();
    link.bindIncoming((raw) => onPacketReceivedFromPeer(raw));
    _outbound = link.sendPacket;
    _initStorage();
  }

  final Map<String, SosPacket> _packetStorage = {};

  final StreamController<List<SosPacket>> _packetsStreamController =
      StreamController<List<SosPacket>>.broadcast();
  Stream<List<SosPacket>> get packetsStream => _packetsStreamController.stream;

  final StreamController<SosPacket> _peerAlerts =
      StreamController<SosPacket>.broadcast();
  Stream<SosPacket> get peerAlerts => _peerAlerts.stream;

  Future<void> Function(SosPacket packet)? _outbound;

  Future<void> _initStorage() async {
    try {
      final savedPackets = await OfflineStorage.loadAllPackets();
      for (final packet in savedPackets) {
        _packetStorage[packet.id] = packet;
      }
      _packetsStreamController.add(_packetStorage.values.toList());
    } catch (e) {
      debugPrint('Bufor offline niedostępny: $e');
    }
  }

  void _remember(SosPacket packet) {
    _packetStorage[packet.id] = packet;
    _packetsStreamController.add(_packetStorage.values.toList());
  }

  /// Zapis lokalny i wysyłka tylko do innych aplikacji Resque w zasięgu.
  Future<void> broadcastMySos(SosPacket packet) async {
    _remember(packet);
    try {
      await OfflineStorage.savePacket(packet);
    } catch (e) {
      debugPrint('Zapis SOS nieudany: $e');
    }
    await _outbound?.call(packet);
  }

  /// Odbiór pakietu od innego telefonu z tą aplikacją.
  Future<void> onPacketReceivedFromPeer(
    String rawJson, {
    bool relay = true,
  }) async {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return;
      final packet = SosPacket.fromJson(Map<String, dynamic>.from(decoded));

      if (_packetStorage.containsKey(packet.id)) return;

      packet.hopCount += 1;
      _remember(packet);

      try {
        await OfflineStorage.savePacket(packet);
      } catch (e) {
        debugPrint('Zapis odebranego SOS nieudany: $e');
      }

      _peerAlerts.add(packet);

      if (relay && packet.hopCount < 5) {
        await _outbound?.call(packet);
      }
    } catch (e) {
      debugPrint('Błąd parsowania pakietu: $e');
    }
  }

  /// Czyści tylko lokalną listę. Nikomu nic nie wysyła.
  Future<void> clearLocalBuffer() async {
    if (_packetStorage.isEmpty) return;
    await OfflineStorage.clearAll();
    _packetStorage.clear();
    _packetsStreamController.add([]);
  }

  List<SosPacket> getAllPackets() => _packetStorage.values.toList();
}
