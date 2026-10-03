enum EmergencyType { medical, fire, flood, trapped, other }

class SosPacket {
  final String id;
  final String senderName;
  final EmergencyType type;
  final String message;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  int hopCount; // Liczba przeskoków między telefonami

  SosPacket({
    required this.id,
    required this.senderName,
    required this.type,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.hopCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'type': type.name,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'hopCount': hopCount,
      };

  factory SosPacket.fromJson(Map<String, dynamic> json) => SosPacket(
        id: json['id'],
        senderName: json['senderName'],
        type: EmergencyType.values.byName(json['type']),
        message: json['message'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        timestamp: DateTime.parse(json['timestamp']),
        hopCount: json['hopCount'] ?? 0,
      );
}