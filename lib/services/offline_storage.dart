import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_packet.dart';

class OfflineStorage {
  static const String _storageKey = 'resque_offline_packets_queue';

  /// Zapisuje pojedynczy pakiet do kolejki na dysku
  static Future<void> savePacket(SosPacket packet) async {
    final prefs = await SharedPreferences.getInstance();
    final packets = await loadAllPackets();

    // Sprawdzenie duplikatów po ID, by nie powielać w kolejce
    final index = packets.indexWhere((p) => p.id == packet.id);
    if (index >= 0) {
      packets[index] = packet; // aktualizacja (np. wyższy hopCount)
    } else {
      packets.add(packet);
    }

    final rawList = packets.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  /// Wczytuje wszystkie zbuforowane pakiety z pamięci urządzenia
  static Future<List<SosPacket>> loadAllPackets() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    return rawList.map((raw) {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return SosPacket.fromJson(jsonMap);
    }).toList();
  }

  /// Usuwa pakiet po pomyślnym wysłaniu do sztabu ratunkowego
  static Future<void> removePacket(String packetId) async {
    final prefs = await SharedPreferences.getInstance();
    final packets = await loadAllPackets();
    packets.removeWhere((p) => p.id == packetId);

    final rawList = packets.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  /// Czyści cały bufor po pełnej synchronizacji ze sztabem
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}