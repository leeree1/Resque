import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_packet.dart';
import 'offline_storage.dart';

class MeshNodeService {
  static final MeshNodeService _instance = MeshNodeService._internal();
  factory MeshNodeService() => _instance;

  MeshNodeService._internal() {
    _initStorageAndConnectivity();
  }

  // Lokalna pamięć podręczna pakietów w RAM
  final Map<String, SosPacket> _packetStorage = {};

  final StreamController<List<SosPacket>> _packetsStreamController =
      StreamController<List<SosPacket>>.broadcast();
  Stream<List<SosPacket>> get packetsStream => _packetsStreamController.stream;

  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusStreamController.stream;

  /// Inicjalizacja: Wczytanie bazy z dysku i nasłuch powrotu Internetu
  Future<void> _initStorageAndConnectivity() async {
    // 1. Wczytaj zachowane pakiety z pamięci flash (Store-and-Forward)
    final savedPackets = await OfflineStorage.loadAllPackets();
    for (var packet in savedPackets) {
      _packetStorage[packet.id] = packet;
    }
    _packetsStreamController.add(_packetStorage.values.toList());

    // 2. Automatyczny Uplink po wykryciu sieci
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasInternet = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (hasInternet && _packetStorage.isNotEmpty) {
        _statusStreamController.add('Wykryto Internet! Synchronizacja bufora z dysku...');
        flushToCentralServer();
      }
    });
  }

  /// Zapisanie i rozgłoszenie własnego sygnału SOS
  Future<void> broadcastMySos(SosPacket packet) async {
    _packetStorage[packet.id] = packet;
    _packetsStreamController.add(_packetStorage.values.toList());

    // Trwały zapis w pamięci urządzenia (Store)
    await OfflineStorage.savePacket(packet);

    // Przekazanie bezprzewodowe (Forward)
    _propagateViaBluetooth(packet);
  }

  /// Odbiór pakietu od innego telefonu w sieci mesh
  Future<void> onPacketReceivedFromPeer(String rawJson) async {
    try {
      final data = jsonDecode(rawJson);
      final packet = SosPacket.fromJson(data);

      // Ochrona przed pętlą: jeśli pakiet już mamy w buforze, ignorujemy
      if (_packetStorage.containsKey(packet.id)) return;

      packet.hopCount += 1;
      _packetStorage[packet.id] = packet;
      _packetsStreamController.add(_packetStorage.values.toList());

      // Trwały zapis odebranego pakietu obcej osoby
      await OfflineStorage.savePacket(packet);

      debugPrint('Mesh Store-and-Forward: Zapisano pakiet ${packet.id} (Skok: ${packet.hopCount})');

      // Podaj dalej kolejnym węzłom
      _propagateViaBluetooth(packet);
    } catch (e) {
      debugPrint('Błąd parsowania pakietu: $e');
    }
  }

  void _propagateViaBluetooth(SosPacket packet) {
    debugPrint('[BLE MESH OUT]: ${packet.id} skok: ${packet.hopCount}');
  }

  /// Wypchnięcie zgłoszeń do serwera po uzyskaniu połączenia
  Future<void> flushToCentralServer() async {
    if (_packetStorage.isEmpty) return;

    debugPrint('UPLINK: Wysyłanie ${_packetStorage.length} pakietów na serwer sztabu...');

    // Po pomyślnej wysyłce czyścimy bazę offline na dysku
    await OfflineStorage.clearAll();
    _packetStorage.clear();
    _packetsStreamController.add([]);

    _statusStreamController.add('Pomyślnie dostarczono pakiety do sztabu!');
  }

  List<SosPacket> getAllPackets() => _packetStorage.values.toList();
}