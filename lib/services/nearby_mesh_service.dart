import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sos_packet.dart';
import 'offline_storage.dart';

class NearbyMeshService extends ChangeNotifier {
  static final NearbyMeshService _instance = NearbyMeshService._internal();
  factory NearbyMeshService() => _instance;
  NearbyMeshService._internal();

  final Strategy strategy = Strategy.P2P_CLUSTER;
  static const String serviceId = "com.example.resque.sos";

  bool _isStarted = false;
  bool _needsSettings = false;
  String _statusMessage = "Inicjalizacja węzła...";
  final Set<String> _connectedEndpoints = {};
  final Set<String> _connectingEndpoints = {};
  final Set<String> _discoveredEndpoints = {};
  final Set<String> _processedPacketIds = {};
  final Map<String, int> _deliveryCounts = {};

  void Function(String rawJson)? _incomingCallback;

  bool get isSupported => !kIsWeb;
  int get peersInRange => _discoveredEndpoints.length + _connectedEndpoints.length;
  String get statusMessage => _statusMessage;
  bool get needsSettings => _needsSettings;

  int deliveredCount(String packetId) => _deliveryCounts[packetId] ?? 0;

  void bindIncoming(void Function(String rawJson) callback) {
    _incomingCallback = callback;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> start() async {
    if (kIsWeb) {
      _statusMessage = "Web: Symulacja BLE (brak sprzętowego Nearby)";
      notifyListeners();
      return;
    }

    if (_isStarted) return;
    _isStarted = true;

    final nodeName = "Resque_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    await startMeshNode(nodeName: nodeName);
  }

  Future<bool> checkAndRequestPermissions() async {
    if (kIsWeb) return false;

    final statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    final isDenied = statuses[Permission.locationWhenInUse]?.isPermanentlyDenied == true ||
        statuses[Permission.bluetoothScan]?.isPermanentlyDenied == true;

    if (isDenied) {
      _needsSettings = true;
      _statusMessage = "Wymagane uprawnienia Bluetooth/Lokalizacji w ustawieniach.";
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> startMeshNode({required String nodeName}) async {
    if (kIsWeb) return;

    final permsGranted = await checkAndRequestPermissions();
    if (!permsGranted) return;

    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}

    _connectedEndpoints.clear();
    _connectingEndpoints.clear();
    _discoveredEndpoints.clear();

    // 1. Nadawanie (Advertising)
    try {
      await Nearby().startAdvertising(
        nodeName,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: (id) {
          _connectedEndpoints.remove(id);
          _connectingEndpoints.remove(id);
          _statusMessage = "Rozłączono węzeł $id";
          notifyListeners();
        },
        serviceId: serviceId,
      );
      _statusMessage = "Nadawanie aktywne (P2P_CLUSTER)";
    } catch (e) {
      _statusMessage = "Status nadawania: $e";
    }

    // 2. Odkrywanie (Discovery)
    try {
      await Nearby().startDiscovery(
        nodeName,
        strategy,
        onEndpointFound: (endpointId, name, sId) async {
          _discoveredEndpoints.add(endpointId);
          _statusMessage = "Wykryto węzeł $name ($endpointId)";
          notifyListeners();

          if (_connectedEndpoints.contains(endpointId) ||
              _connectingEndpoints.contains(endpointId)) {
            return;
          }

          if (nodeName.compareTo(name) > 0) {
            _connectingEndpoints.add(endpointId);
            try {
              await Nearby().requestConnection(
                nodeName,
                endpointId,
                onConnectionInitiated: _onConnectionInitiated,
                onConnectionResult: _onConnectionResult,
                onDisconnected: (id) {
                  _connectedEndpoints.remove(id);
                  _connectingEndpoints.remove(id);
                  notifyListeners();
                },
              );
            } catch (e) {
              _connectingEndpoints.remove(endpointId);
            }
          }
        },
        onEndpointLost: (id) {
          _discoveredEndpoints.remove(id);
          _connectingEndpoints.remove(id);
          _connectedEndpoints.remove(id);
          notifyListeners();
        },
        serviceId: serviceId,
      );
    } catch (e) {
      _statusMessage = "Status odkrywania: $e";
    }

    notifyListeners();
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) async {
    try {
      await Nearby().acceptConnection(
        endpointId,
        onPayLoadRecieved: (endId, payload) {
          if (payload.type == PayloadType.BYTES && payload.bytes != null) {
            _handleIncomingPayload(payload.bytes!, endId);
          }
        },
      );
    } catch (e) {
      debugPrint("Błąd acceptConnection: $e");
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    _connectingEndpoints.remove(endpointId);

    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(endpointId);
      _statusMessage = "Połączono z węzłem $endpointId";
    } else {
      _connectedEndpoints.remove(endpointId);
    }
    notifyListeners();
  }

  Future<void> sendPacket(SosPacket packet) async {
    await broadcastSos(packet);
  }

  Future<void> broadcastSos(SosPacket packet) async {
    _processedPacketIds.add(packet.id);

    if (_connectedEndpoints.isEmpty) {
      _statusMessage = "Brak węzłów w zasięgu direct. Pakiet czeka w kolejce.";
      notifyListeners();
      return;
    }

    for (final endpointId in _connectedEndpoints.toList()) {
      await _sendPacketToEndpoint(endpointId, packet);
    }
  }

  Future<void> _sendPacketToEndpoint(String endpointId, SosPacket packet) async {
    try {
      final jsonString = jsonEncode(packet.toJson());
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      await Nearby().sendBytesPayload(endpointId, bytes);
      _deliveryCounts[packet.id] = (_deliveryCounts[packet.id] ?? 0) + 1;
      _statusMessage = "Dostarczono pakiet ${packet.id} do węzła $endpointId";
      notifyListeners();
    } catch (e) {
      debugPrint("Błąd sendBytesPayload: $e");
    }
  }

  void _handleIncomingPayload(Uint8List bytes, String sourceEndpointId) async {
    try {
      final raw = utf8.decode(bytes);
      final jsonMap = jsonDecode(raw);
      final packet = SosPacket.fromJson(jsonMap);

      if (_processedPacketIds.contains(packet.id)) return;
      _processedPacketIds.add(packet.id);

      packet.hopCount += 1;
      await OfflineStorage.savePacket(packet);

      _statusMessage = "Odebrano SOS: ${packet.senderName} (skok: ${packet.hopCount})";
      notifyListeners();

      if (_incomingCallback != null) {
        _incomingCallback!(raw);
      }

      for (final endpointId in _connectedEndpoints.toList()) {
        if (endpointId != sourceEndpointId) {
          await _sendPacketToEndpoint(endpointId, packet);
        }
      }
    } catch (e) {
      debugPrint("Błąd przetwarzania odebranego pakietu: $e");
    }
  }

  Future<void> stopAll() async {
    _connectedEndpoints.clear();
    _connectingEndpoints.clear();
    _discoveredEndpoints.clear();
    _isStarted = false;
    if (!kIsWeb) {
      try {
        await Nearby().stopAllEndpoints();
        await Nearby().stopAdvertising();
        await Nearby().stopDiscovery();
      } catch (_) {}
    }
    notifyListeners();
  }
}