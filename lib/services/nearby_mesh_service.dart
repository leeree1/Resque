import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sos_packet.dart';
import 'offline_storage.dart';

enum MeshRole { auto, advertiserOnly, discovererOnly }

class NearbyMeshService extends ChangeNotifier {
  static final NearbyMeshService _instance = NearbyMeshService._internal();
  factory NearbyMeshService() => _instance;
  NearbyMeshService._internal();

  // Zmiana na P2P_STAR eliminuje zawieszanie anteny radiowej na wielu procesorach
  final Strategy strategy = Strategy.P2P_STAR;

  // Nowy identyfikator unieważnia zawieszone w tle sesje Google Nearby
  static const String serviceId = "com.resque.emergency.mesh.v3";

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
  int get peersInRange =>
      _discoveredEndpoints.length + _connectedEndpoints.length;
  String get statusMessage => _statusMessage;
  bool get needsSettings => _needsSettings;

  int deliveredCount(String packetId) => _deliveryCounts[packetId] ?? 0;

  void bindIncoming(void Function(String rawJson) callback) {
    _incomingCallback = callback;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> start({MeshRole role = MeshRole.auto}) async {
    if (kIsWeb) {
      _statusMessage = "Web: Symulacja BLE (brak sprzętowego Nearby)";
      notifyListeners();
      return;
    }

    if (_isStarted) return;
    _isStarted = true;

    final randomSuffix = DateTime.now().microsecondsSinceEpoch
        .toString()
        .substring(9);
    final nodeName = "Resque_$randomSuffix";
    await startMeshNode(nodeName: nodeName, role: role);
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

    final isDenied =
        statuses[Permission.locationWhenInUse]?.isPermanentlyDenied == true ||
        statuses[Permission.bluetoothScan]?.isPermanentlyDenied == true;

    if (isDenied) {
      _needsSettings = true;
      _statusMessage =
          "Wymagane uprawnienia Bluetooth/Lokalizacji w Ustawieniach.";
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> startMeshNode({
    required String nodeName,
    MeshRole role = MeshRole.auto,
  }) async {
    if (kIsWeb) return;

    final permsGranted = await checkAndRequestPermissions();
    if (!permsGranted) return;

    // Twardy reset poprzednich sesji i krótka pauza na zwolnienie zasobów radiowych
    try {
      await Nearby().stopAllEndpoints();
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Future.delayed(const Duration(milliseconds: 350));
    } catch (_) {}

    _connectedEndpoints.clear();
    _connectingEndpoints.clear();
    _discoveredEndpoints.clear();

    // 1. Nadawanie (Advertising) - pomijane, jeśli wymuszono tylko odbiór
    if (role != MeshRole.discovererOnly) {
      try {
        await Nearby().startAdvertising(
          nodeName,
          strategy,
          onConnectionInitiated: _onConnectionInitiated,
          onConnectionResult: _onConnectionResult,
          onDisconnected: (id) {
            _connectedEndpoints.remove(id);
            _connectingEndpoints.remove(id);
            _statusMessage = "Rozłączono z $id";
            notifyListeners();
          },
          serviceId: serviceId,
        );
        _statusMessage = "Nadawanie aktywne ($nodeName)";
      } catch (e) {
        if (e.toString().contains("8001")) {
          debugPrint("Nearby: Kod 8001 (nadawanie w toku) - kontynuuję.");
        } else {
          _statusMessage = "Status nadawania: $e";
        }
      }
    }

    // 2. Odkrywanie (Discovery) - pomijane, jeśli wymuszono tylko nadawanie
    if (role != MeshRole.advertiserOnly) {
      try {
        await Nearby().startDiscovery(
          nodeName,
          strategy,
          onEndpointFound: (endpointId, name, sId) async {
            debugPrint("Nearby: ZNALEZIONO WĘZEŁ $name ($endpointId)");
            _discoveredEndpoints.add(endpointId);
            _statusMessage = "Wykryto węzeł: $name";
            notifyListeners();

            if (_connectedEndpoints.contains(endpointId) ||
                _connectingEndpoints.contains(endpointId)) {
              return;
            }

            // W trybie auto: asymetria nazw zapobiega konfliktom 8003
            // W trybie discovererOnly: zawsze inicjuje połączenie
            final shouldConnect =
                (role == MeshRole.discovererOnly) ||
                (nodeName.compareTo(name) > 0);

            if (shouldConnect) {
              _connectingEndpoints.add(endpointId);
              debugPrint("Nearby: Wysyłam prośbę o połączenie do $name...");
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
                debugPrint("Błąd requestConnection: $e");
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
        if (role == MeshRole.discovererOnly) {
          _statusMessage = "Nasłuch SOS aktywny...";
        }
      } catch (e) {
        _statusMessage = "Błąd discovery: $e";
      }
    }

    notifyListeners();
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) async {
    debugPrint(
      "Nearby: Inicjacja połączenia z ${info.endpointName} ($endpointId)",
    );
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
      _statusMessage = "POŁĄCZONO Z WĘZŁEM!";
      debugPrint("Nearby: Połączono z $endpointId");
    } else {
      _connectedEndpoints.remove(endpointId);
      _statusMessage = "Nie udało się połączyć ($status)";
    }
    notifyListeners();
  }

  Future<void> sendPacket(SosPacket packet) async {
    await broadcastSos(packet);
  }

  Future<void> broadcastSos(SosPacket packet) async {
    _processedPacketIds.add(packet.id);

    if (_connectedEndpoints.isEmpty) {
      _statusMessage = "Brak aktywnych połączeń. Pakiet zbuforowany.";
      notifyListeners();
      return;
    }

    for (final endpointId in _connectedEndpoints.toList()) {
      await _sendPacketToEndpoint(endpointId, packet);
    }
  }

  Future<void> _sendPacketToEndpoint(
    String endpointId,
    SosPacket packet,
  ) async {
    try {
      final jsonString = jsonEncode(packet.toJson());
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      await Nearby().sendBytesPayload(endpointId, bytes);
      _deliveryCounts[packet.id] = (_deliveryCounts[packet.id] ?? 0) + 1;
      _statusMessage = "Wysłano SOS do węzła $endpointId";
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

      _statusMessage =
          "ODEBRANO SOS: ${packet.senderName} (skok: ${packet.hopCount})";
      notifyListeners();

      if (_incomingCallback != null) {
        _incomingCallback!(raw);
      }

      // Podaj dalej pakiet (Mesh Relay)
      for (final endpointId in _connectedEndpoints.toList()) {
        if (endpointId != sourceEndpointId) {
          await _sendPacketToEndpoint(endpointId, packet);
        }
      }
    } catch (e) {
      debugPrint("Błąd przetwarzania pakietu: $e");
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
