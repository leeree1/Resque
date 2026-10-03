import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/sos_packet.dart';
import 'mesh_engine.dart';
import 'offline_storage.dart';

/// Synchronizacja pakietów SOS z Firebase Realtime Database.
///
/// Model: pakiety płyną wyłącznie przez mesh (Nearby Connections). Każdy
/// telefon, który ma internet, wypycha zawartość swojego lokalnego bufora
/// do /sos_packets i czyści bufor. Odczyt jest publiczny — każdy użytkownik
/// z aplikacją widzi wszystkie aktywne SOS-y. Wpisy wygasają po 7 dniach
/// (pole expiresAt, wymuszane regułami bazy i filtrem po stronie klienta).
class FirebaseSyncService {
  static DatabaseReference? _ref;

  /// Bezpieczny dostęp do bazy — zwraca null, gdy Firebase nie jest
  /// zainicjalizowane (testy, web, błąd startu). Synchronizacja jest wtedy
  /// po prostu wyłączona, a mesh działa dalej.
  static DatabaseReference? get _db {
    if (Firebase.apps.isEmpty) return null;
    return _ref ??= FirebaseDatabase.instance.ref('sos_packets');
  }

  static const Duration _ttl = Duration(days: 7);

  /// Wypycha lokalny bufor do Firebase. Zwraca true, gdy synchronizacja
  /// faktycznie nastąpiła (był internet i bufor był niepusty).
  static Future<bool> syncLocalQueue() async {
    final db = _db;
    if (db == null) return false;

    final results = await Connectivity().checkConnectivity();
    final hasInternet = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    if (!hasInternet) return false;

    final packets = await OfflineStorage.loadAllPackets();
    if (packets.isEmpty) return false;

    for (final packet in packets) {
      try {
        await db.child(packet.id).set({
          ...packet.toJson(),
          'uploadedAt': ServerValue.timestamp,
          'expiresAt': DateTime.now().add(_ttl).millisecondsSinceEpoch,
        });
        await OfflineStorage.removePacket(packet.id);
      } catch (e) {
        debugPrint('FirebaseSync: błąd wysyłki ${packet.id}: $e');
        return false;
      }
    }
    debugPrint('FirebaseSync: zsynchronizowano ${packets.length} pakietów');
    return true;
  }

  /// Próba synchronizacji w tle — bez blokowania radia mesh.
  static void trySyncInBackground() {
    unawaited(syncLocalQueue());
  }

  /// Strumień łączący pakiety z lokalnego mesha i z Firebase.
  /// Firebase pełni rolę "ducha" pakietów: gdy lokalny bufor zostanie
  /// wyczyszczony po synchronizacji, pakiety nadal są widoczne z chmury.
  static Stream<List<SosPacket>> watchAllSos() {
    final controller = StreamController<List<SosPacket>>.broadcast();
    final merged = <String, SosPacket>{};
    StreamSubscription<List<SosPacket>>? meshSub;
    StreamSubscription<DatabaseEvent>? firebaseSub;

    controller.onListen = () {
      meshSub = MeshNodeService().packetsStream.listen((packets) {
        merged
          ..clear()
          ..addEntries(packets.map((p) => MapEntry(p.id, p)));
        controller.add(merged.values.toList());
      });

      firebaseSub = _db?.onValue.listen((event) {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final child in event.snapshot.children) {
          final value = child.value;
          if (value is! Map) continue;
          final map = Map<String, dynamic>.from(value);
          final expiresAt = map['expiresAt'];
          if (expiresAt is num && expiresAt < now) continue;
          try {
            final packet = SosPacket.fromJson(map);
            merged.putIfAbsent(packet.id, () => packet);
          } catch (_) {}
        }
        controller.add(merged.values.toList());
      });
    };

    controller.onCancel = () async {
      await meshSub?.cancel();
      await firebaseSub?.cancel();
    };

    return controller.stream;
  }
}
