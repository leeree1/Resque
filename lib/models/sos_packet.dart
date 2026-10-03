enum EmergencyType { medical, fire, flood, trapped, other }

enum SosAudience { everyoneNearby, specificPerson }

String emergencyTypeLabel(EmergencyType type) {
  switch (type) {
    case EmergencyType.medical:
      return 'Medyczne';
    case EmergencyType.fire:
      return 'Pożar';
    case EmergencyType.flood:
      return 'Woda / Powódź';
    case EmergencyType.trapped:
      return 'Uwięzienie';
    case EmergencyType.other:
      return 'Inne';
  }
}

class SosSharedLine {
  final String label;
  final String value;

  const SosSharedLine(this.label, this.value);
}

class SosPacket {
  final String id;
  final String senderName;
  final EmergencyType type;
  final String message;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;
  int hopCount;

  final bool shareType;
  final bool shareSenderName;
  final bool shareLocation;
  final bool shareMessage;
  final bool shareTimestamp;
  final SosAudience audience;

  SosPacket({
    required this.id,
    required this.senderName,
    required this.type,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.hopCount = 0,
    this.shareType = true,
    this.shareSenderName = true,
    this.shareLocation = true,
    this.shareMessage = true,
    this.shareTimestamp = true,
    this.audience = SosAudience.everyoneNearby,
  });

  String get audienceLabel {
    switch (audience) {
      case SosAudience.everyoneNearby:
        return 'Wszyscy wokół z aplikacją Resque';
      case SosAudience.specificPerson:
        return 'Konkretna osoba';
    }
  }

  String? get locationLabel {
    if (!shareLocation || latitude == null || longitude == null) return null;
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  String? get timestampLabel {
    final time = timestamp?.toLocal();
    if (!shareTimestamp || time == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.day)}.${two(time.month)}.${time.year} ${two(time.hour)}:${two(time.minute)}';
  }

  List<SosSharedLine> get sharedLines {
    return [
      if (shareType) SosSharedLine('Rodzaj', emergencyTypeLabel(type)),
      if (shareSenderName && senderName.trim().isNotEmpty)
        SosSharedLine('Nazwa', senderName.trim()),
      if (locationLabel != null) SosSharedLine('Pozycja', locationLabel!),
      if (timestampLabel != null) SosSharedLine('Czas', timestampLabel!),
      if (shareMessage && message.trim().isNotEmpty)
        SosSharedLine('Wiadomość', message.trim()),
    ];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': shareSenderName ? senderName : '',
        'type': shareType ? type.name : null,
        'message': shareMessage ? message : '',
        'latitude': shareLocation ? latitude : null,
        'longitude': shareLocation ? longitude : null,
        'timestamp': shareTimestamp ? timestamp?.toIso8601String() : null,
        'hopCount': hopCount,
        'shareType': shareType,
        'shareSenderName': shareSenderName,
        'shareLocation': shareLocation,
        'shareMessage': shareMessage,
        'shareTimestamp': shareTimestamp,
        'audience': audience.name,
      };

  factory SosPacket.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final lat = json['latitude'];
    final lng = json['longitude'];
    final rawMessage = json['message'] as String? ?? '';
    final rawSender = json['senderName'] as String? ?? '';
    final rawTime = json['timestamp'] as String?;
    final audienceName = json['audience'] as String?;

    return SosPacket(
      id: json['id'] as String,
      senderName: rawSender,
      type: typeName == null
          ? EmergencyType.other
          : EmergencyType.values.byName(typeName),
      message: rawMessage,
      latitude: lat == null ? null : (lat as num).toDouble(),
      longitude: lng == null ? null : (lng as num).toDouble(),
      timestamp: rawTime == null ? null : DateTime.parse(rawTime),
      hopCount: json['hopCount'] as int? ?? 0,
      shareType: json['shareType'] as bool? ?? typeName != null,
      shareSenderName:
          json['shareSenderName'] as bool? ?? rawSender.isNotEmpty,
      shareLocation: json['shareLocation'] as bool? ?? lat != null,
      shareMessage: json['shareMessage'] as bool? ?? rawMessage.isNotEmpty,
      shareTimestamp: json['shareTimestamp'] as bool? ?? rawTime != null,
      audience: SosAudience.values.asNameMap()[audienceName] ??
          SosAudience.everyoneNearby,
    );
  }
}

/// Wybór tego, co ma wyjść z telefonu po kliknięciu SOS.
class SosDraft {
  static const int maxMessageLength = 120;
  static const int maxSenderNameLength = 32;

  EmergencyType type;
  bool shareType;
  bool shareLocation;
  bool shareSenderName;
  bool shareTimestamp;
  bool shareMessage;
  String senderName;
  String message;
  SosAudience audience;

  SosDraft({
    this.type = EmergencyType.medical,
    this.shareType = true,
    this.shareLocation = true,
    this.shareSenderName = true,
    this.shareTimestamp = true,
    this.shareMessage = false,
    this.senderName = 'Osoba w pobliżu',
    this.message = '',
    this.audience = SosAudience.everyoneNearby,
  });

  bool get hasAnyField =>
      shareType ||
      shareLocation ||
      shareSenderName ||
      shareTimestamp ||
      shareMessage;

  String? validate() {
    if (audience != SosAudience.everyoneNearby) {
      return 'Wysyłka do konkretnej osoby nie jest jeszcze włączona. Na razie wybierz wszystkich wokół.';
    }
    if (!hasAnyField) {
      return 'Wybierz przynajmniej jedną informację.';
    }
    final name = senderName.trim();
    if (shareSenderName && name.isEmpty) {
      return 'Wpisz nazwę albo odznacz jej wysyłanie.';
    }
    if (shareSenderName && name.length > maxSenderNameLength) {
      return 'Nazwa może mieć najwyżej $maxSenderNameLength znaków.';
    }
    final note = message.trim();
    if (shareMessage && note.isEmpty) {
      return 'Wpisz wiadomość albo wyłącz dołączenie wiadomości.';
    }
    if (shareMessage && note.length > maxMessageLength) {
      return 'Wiadomość może mieć najwyżej $maxMessageLength znaków.';
    }
    return null;
  }

  List<String> get previewLines => [
        if (shareType) 'Rodzaj: ${emergencyTypeLabel(type)}',
        if (shareLocation) 'Pozycja GPS',
        if (shareSenderName && senderName.trim().isNotEmpty)
          'Nazwa: ${senderName.trim()}',
        if (shareTimestamp) 'Czas wysłania',
        if (shareMessage)
          'Wiadomość: ${message.trim().isEmpty ? '—' : message.trim()}',
        'Odbiór: tylko aplikacje Resque w zasięgu',
      ];

  SosPacket toPacket({
    required String id,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
  }) {
    final error = validate();
    if (error != null) {
      throw StateError(error);
    }
    if (shareLocation && (latitude == null || longitude == null)) {
      throw StateError('Brak pozycji GPS');
    }

    return SosPacket(
      id: id,
      senderName: shareSenderName ? senderName.trim() : '',
      type: type,
      message: shareMessage ? message.trim() : '',
      latitude: shareLocation ? latitude : null,
      longitude: shareLocation ? longitude : null,
      timestamp: shareTimestamp ? timestamp : null,
      shareType: shareType,
      shareSenderName: shareSenderName,
      shareLocation: shareLocation,
      shareMessage: shareMessage,
      shareTimestamp: shareTimestamp,
      audience: SosAudience.everyoneNearby,
    );
  }
}
