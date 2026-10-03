import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_connections/nearby_connections.dart' as nearby;
import 'package:permission_handler/permission_handler.dart';

import '../models/sos_packet.dart';

/// Cichy kanał między telefonami z aplikacją Resque.
///
/// Google Nearby Connections widzą tylko aplikacje z tym samym serviceId.
/// Nie wysyłamy powiadomienia systemowego i nie ogłaszamy SOS telefonom bez Resque.
class NearbyMeshService extends ChangeNotifier {
  static final NearbyMeshService _instance = NearbyMeshService._();
  factory NearbyMeshService() => _instance;
  NearbyMeshService._();

  static const String serviceId = 'com.example.resque';
  static const String _nickname = 'Resque';

  final Set<String> _peers = {};
  final Set<String> _connected = {};
  final Set<String> _inviting = {};
  final Map<String, SosPacket> _outbound = {};
  final List<String> _outboundOrder = [];
  final Map<String, Set<String>> _delivered = {};

  Future<void> Function(String rawJson)? _onRaw;
  Future<void>? _starting;
  Future<void> _flushTail = Future<void>.value();

  bool _running = false;
  bool permissionsGranted = false;
  bool needsSettings = false;
  String statusMessage = 'Uruchamiam nasłuch aplikacji Resque…';

  bool get isAndroidDevice =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isSupported => isAndroidDevice;

  bool get isRunning => _running;

  int get peersInRange => _peers.length;

  int deliveredCount(String? packetId) {
    if (packetId == null) return 0;
    return _delivered[packetId]?.length ?? 0;
  }

  void bindIncoming(Future<void> Function(String rawJson) onRaw) {
    _onRaw = onRaw;
  }

  Future<void> start() {
    return _starting ??= _startInternal();
  }

  Future<void> openSettings() => openAppSettings();

  Future<void> sendPacket(SosPacket packet) async {
    _rememberOutbound(packet);
    await start();
    if (_running) {
      await _enqueueFlush();
    }
    notifyListeners();
  }

  Future<void> _startInternal() async {
    try {
      if (!isAndroidDevice) {
        _running = false;
        permissionsGranted = false;
        statusMessage =
            'Nasłuch w zasięgu działa na telefonie z Androidem. Na tym urządzeniu nikt obok nie dostanie sygnału.';
        return;
      }

      final allowed = await _requestPermissions();
      permissionsGranted = allowed;
      if (!allowed) {
        _running = false;
        statusMessage =
            'Brak zgody na urządzenia w pobliżu. Druga aplikacja Resque nie odbierze SOS. Telefony bez tej aplikacji i tak nie dostaną powiadomienia.';
        return;
      }

      final gpsOn = await Geolocator.isLocationServiceEnabled();
      if (!gpsOn) {
        statusMessage =
            'Włącz lokalizację w systemie, żeby znaleźć drugą aplikację. Współrzędne dołączamy do SOS tylko, gdy je zaznaczysz.';
      }

      var advertising = false;
      var discovering = false;
      Object? failure;

      try {
        advertising = await nearby.Nearby().startAdvertising(
          _nickname,
          nearby.Strategy.P2P_CLUSTER,
          onConnectionInitiated: _onInitiated,
          onConnectionResult: _onResult,
          onDisconnected: _onDisconnected,
          serviceId: serviceId,
        );
      } catch (e) {
        failure = e;
        debugPrint('Resque advertise: $e');
      }

      try {
        discovering = await nearby.Nearby().startDiscovery(
          _nickname,
          nearby.Strategy.P2P_CLUSTER,
          onEndpointFound: _onEndpointFound,
          onEndpointLost: _onEndpointLost,
          serviceId: serviceId,
        );
      } catch (e) {
        failure ??= e;
        debugPrint('Resque discovery: $e');
      }

      _running = advertising || discovering;
      if (_running) {
        statusMessage = gpsOn
            ? 'Szukam innych aplikacji Resque w zasięgu. Powiadomienia systemowe nie wychodzą.'
            : statusMessage;
      } else {
        statusMessage =
            'Nie udało się włączyć nasłuchu (${_shortError(failure)}). SOS nie wyjdzie poza ten telefon.';
      }
    } finally {
      _starting = null;
      notifyListeners();
    }
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    bool granted(Permission permission) {
      final status = statuses[permission];
      if (status == null) return false;
      return status.isGranted || status.isLimited;
    }

    needsSettings = statuses.values.any((status) => status.isPermanentlyDenied);

    final locationOk = granted(Permission.location);
    final radioOk = granted(Permission.bluetoothScan) &&
        granted(Permission.bluetoothAdvertise) &&
        granted(Permission.bluetoothConnect);
    return locationOk && radioOk;
  }

  void _onEndpointFound(String id, String name, String foundServiceId) {
    if (foundServiceId.isNotEmpty && foundServiceId != serviceId) return;
    if (name.isNotEmpty && name != _nickname) return;

    _peers.add(id);
    notifyListeners();

    if (_connected.contains(id) || _inviting.contains(id)) return;
    _inviting.add(id);
    nearby.Nearby()
        .requestConnection(
          _nickname,
          id,
          onConnectionInitiated: _onInitiated,
          onConnectionResult: _onResult,
          onDisconnected: _onDisconnected,
        )
        .catchError((Object e) {
      _inviting.remove(id);
      debugPrint('Resque requestConnection: $e');
      return false;
    });
  }

  void _onEndpointLost(String? id) {
    if (id == null) return;
    _inviting.remove(id);
    if (!_connected.contains(id)) {
      _peers.remove(id);
      notifyListeners();
    }
  }

  void _onInitiated(String id, nearby.ConnectionInfo info) {
    if (info.endpointName.isNotEmpty && info.endpointName != _nickname) {
      unawaited(nearby.Nearby().rejectConnection(id));
      return;
    }
    unawaited(_accept(id));
  }

  Future<void> _accept(String id) async {
    try {
      await nearby.Nearby().acceptConnection(
        id,
        onPayLoadRecieved: _onPayload,
        onPayloadTransferUpdate: (_, _) {},
      );
    } catch (e) {
      debugPrint('Resque accept: $e');
    }
  }

  void _onResult(String id, nearby.Status status) {
    _inviting.remove(id);
    if (status == nearby.Status.CONNECTED) {
      _connected.add(id);
      _peers.add(id);
      _enqueueFlush();
    }
    notifyListeners();
  }

  void _onDisconnected(String id) {
    _connected.remove(id);
    _peers.remove(id);
    _inviting.remove(id);
    notifyListeners();
  }

  void _onPayload(String endpointId, nearby.Payload payload) {
    if (payload.type != nearby.PayloadType.BYTES) return;
    final bytes = payload.bytes;
    if (bytes == null || bytes.isEmpty) return;

    final raw = utf8.decode(bytes, allowMalformed: true);
    final handler = _onRaw;
    if (handler == null) return;
    handler(raw);
  }

  void _rememberOutbound(SosPacket packet) {
    _outbound[packet.id] = packet;
    _outboundOrder.remove(packet.id);
    _outboundOrder.add(packet.id);
    while (_outboundOrder.length > 30) {
      final removed = _outboundOrder.removeAt(0);
      _outbound.remove(removed);
    }
  }

  Future<void> _enqueueFlush() {
    final next = _flushTail.then((_) => _flushBody());
    _flushTail = next.catchError((Object e) {
      debugPrint('Resque flush: $e');
    });
    return next;
  }

  Future<void> _flushBody() async {
    if (!_running || _connected.isEmpty || _outbound.isEmpty) return;

    final packets = _outboundOrder
        .map((id) => _outbound[id])
        .whereType<SosPacket>()
        .toList();
    final endpoints = List<String>.of(_connected);

    for (final packet in packets) {
      final raw = Uint8List.fromList(utf8.encode(jsonEncode(packet.toJson())));
      for (final endpoint in endpoints) {
        if (!_connected.contains(endpoint)) continue;
        final sent = _delivered.putIfAbsent(packet.id, () => <String>{});
        if (sent.contains(endpoint)) continue;
        try {
          await nearby.Nearby().sendBytesPayload(endpoint, raw);
          sent.add(endpoint);
        } catch (e) {
          debugPrint('Resque send: $e');
        }
      }
    }
    notifyListeners();
  }

  String _shortError(Object? error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    return error?.toString() ?? 'brak szczegółów';
  }
}
