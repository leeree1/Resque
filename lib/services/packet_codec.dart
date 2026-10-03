import '../models/sos_packet.dart';

class PacketCodec {
  static String encode(SosPacket packet) {
    return [
      packet.id,
      packet.senderName,
      packet.type.index,
      packet.latitude?.toStringAsFixed(5) ?? '',
      packet.longitude?.toStringAsFixed(5) ?? '',
      packet.hopCount,
      packet.message.replaceAll('|', ' '),
    ].join('|');
  }

  static SosPacket? decode(String raw) {
    try {
      final parts = raw.split('|');
      if (parts.length < 7) return null;

      return SosPacket(
        id: parts[0],
        senderName: parts[1],
        type: EmergencyType.values[int.parse(parts[2])],
        latitude: double.parse(parts[3]),
        longitude: double.parse(parts[4]),
        hopCount: int.parse(parts[5]),
        message: parts.sublist(6).join('|'),
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}