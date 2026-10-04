enum EmergencyType {
  medical, // POMOC MEDYCZNA
  evacuation, // EWAKUACJA
  supplies, // ŻYWNOŚĆ / WODA
  trapped, // JESTEM UWIĘZIONY
  other // INNE
}

enum ReportStatus {
  newReport, // NOWE
  confirmed, // POTWIERDZONE
  inProgress, // W TRAKCIE
  resolved // ROZWIĄZANE
}

class SosPacket {
  final String id;
  final String senderName;
  final EmergencyType type;
  final String message;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  int hopCount;
  final bool isAck;
  final String bloodType;
  final int victimsCount;
  ReportStatus status;

  SosPacket({
    required this.id,
    required this.senderName,
    required this.type,
    required this.message,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.hopCount = 0,
    this.isAck = false,
    this.bloodType = 'A+',
    this.victimsCount = 2,
    this.status = ReportStatus.newReport,
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
        'isAck': isAck,
        'bloodType': bloodType,
        'victimsCount': victimsCount,
        'status': status.name,
      };

  factory SosPacket.fromJson(Map<String, dynamic> json) {
    return SosPacket(
      id: json['id'] as String,
      senderName: json['senderName'] as String? ?? 'Nieznany',
      type: EmergencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyType.trapped,
      ),
      message: json['message'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      hopCount: (json['hopCount'] as num?)?.toInt() ?? 0,
      isAck: json['isAck'] as bool? ?? false,
      bloodType: json['bloodType'] as String? ?? 'A+',
      victimsCount: (json['victimsCount'] as num?)?.toInt() ?? 2,
      status: ReportStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReportStatus.newReport,
      ),
    );
  }
}