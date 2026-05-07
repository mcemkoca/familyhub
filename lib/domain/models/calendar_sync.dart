// External Calendar Sync Domain Models
// Harici Takvim Senkronizasyonu Veri Modelleri

/// Takvim sağlayıcısı
enum CalendarProvider { google, apple, outlook, local }

/// Senkronizasyon yönü
enum SyncDirection { toExternal, fromExternal, bidirectional }

/// Çakışma stratejisi
enum ConflictStrategy { lastWriteWins, manual, merge, sourcePriority }

/// Takvim bağlantısı
class CalendarConnection {
  final String id;
  final CalendarProvider provider;
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime connectedAt;
  final DateTime? lastSyncAt;
  final bool syncEnabled;
  final SyncDirection syncDirection;
  final List<ExternalCalendar> calendars;
  final List<String> selectedCalendarIds;
  final ConflictStrategy conflictStrategy;

  const CalendarConnection({
    required this.id,
    required this.provider,
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.connectedAt,
    this.lastSyncAt,
    this.syncEnabled = true,
    this.syncDirection = SyncDirection.bidirectional,
    this.calendars = const [],
    this.selectedCalendarIds = const [],
    this.conflictStrategy = ConflictStrategy.lastWriteWins,
  });

  CalendarConnection copyWith({
    DateTime? lastSyncAt,
    bool? syncEnabled,
    SyncDirection? syncDirection,
    List<ExternalCalendar>? calendars,
    List<String>? selectedCalendarIds,
    ConflictStrategy? conflictStrategy,
  }) {
    return CalendarConnection(
      id: id,
      provider: provider,
      userId: userId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      connectedAt: connectedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncDirection: syncDirection ?? this.syncDirection,
      calendars: calendars ?? this.calendars,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.name,
    'userId': userId,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'connectedAt': connectedAt.toIso8601String(),
    'lastSyncAt': lastSyncAt?.toIso8601String(),
    'syncEnabled': syncEnabled,
    'syncDirection': syncDirection.name,
    'calendars': calendars.map((c) => c.toJson()).toList(),
    'selectedCalendarIds': selectedCalendarIds,
    'conflictStrategy': conflictStrategy.name,
  };

  factory CalendarConnection.fromJson(Map<String, dynamic> json) {
    return CalendarConnection(
      id: json['id'] as String,
      provider: CalendarProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => CalendarProvider.local,
      ),
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      syncEnabled: json['syncEnabled'] as bool? ?? true,
      syncDirection: SyncDirection.values.firstWhere(
        (e) => e.name == json['syncDirection'],
        orElse: () => SyncDirection.bidirectional,
      ),
      calendars: (json['calendars'] as List<dynamic>?)
          ?.map((e) => ExternalCalendar.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      selectedCalendarIds: (json['selectedCalendarIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      conflictStrategy: ConflictStrategy.values.firstWhere(
        (e) => e.name == json['conflictStrategy'],
        orElse: () => ConflictStrategy.lastWriteWins,
      ),
    );
  }
}

/// Harici takvim (Google/Apple/Outlook)
class ExternalCalendar {
  final String id;
  final String name;
  final String? description;
  final bool isPrimary;
  final bool isSelected;
  final String? color;
  final String? timeZone;

  const ExternalCalendar({
    required this.id,
    required this.name,
    this.description,
    this.isPrimary = false,
    this.isSelected = false,
    this.color,
    this.timeZone,
  });

  ExternalCalendar copyWith({bool? isSelected}) {
    return ExternalCalendar(
      id: id,
      name: name,
      description: description,
      isPrimary: isPrimary,
      isSelected: isSelected ?? this.isSelected,
      color: color,
      timeZone: timeZone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'isPrimary': isPrimary,
    'isSelected': isSelected,
    'color': color,
    'timeZone': timeZone,
  };

  factory ExternalCalendar.fromJson(Map<String, dynamic> json) {
    return ExternalCalendar(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
      color: json['color'] as String?,
      timeZone: json['timeZone'] as String?,
    );
  }
}

/// Harici etkinlik
class ExternalEvent {
  final String id;
  final String? externalId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? location;
  final bool isAllDay;
  final String? recurrenceRule;
  final List<int> reminders;
  final String? calendarId;
  final DateTime? lastModified;

  const ExternalEvent({
    required this.id,
    this.externalId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.location,
    this.isAllDay = false,
    this.recurrenceRule,
    this.reminders = const [],
    this.calendarId,
    this.lastModified,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'externalId': externalId,
    'title': title,
    'description': description,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'location': location,
    'isAllDay': isAllDay,
    'recurrenceRule': recurrenceRule,
    'reminders': reminders,
    'calendarId': calendarId,
    'lastModified': lastModified?.toIso8601String(),
  };

  factory ExternalEvent.fromJson(Map<String, dynamic> json) {
    return ExternalEvent(
      id: json['id'] as String,
      externalId: json['externalId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      location: json['location'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      recurrenceRule: json['recurrenceRule'] as String?,
      reminders: (json['reminders'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      calendarId: json['calendarId'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }
}

/// Senkronizasyon sonucu
class SyncResult {
  final int added;
  final int updated;
  final int deleted;
  final int conflicts;
  final String? error;
  final DateTime timestamp;

  const SyncResult({
    this.added = 0,
    this.updated = 0,
    this.deleted = 0,
    this.conflicts = 0,
    this.error,
    required this.timestamp,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  int get total => added + updated + deleted;

  Map<String, dynamic> toJson() => {
    'added': added,
    'updated': updated,
    'deleted': deleted,
    'conflicts': conflicts,
    'error': error,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      added: json['added'] as int? ?? 0,
      updated: json['updated'] as int? ?? 0,
      deleted: json['deleted'] as int? ?? 0,
      conflicts: json['conflicts'] as int? ?? 0,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Çakışma kaydı
class Conflict {
  final ExternalEvent localEvent;
  final ExternalEvent remoteEvent;
  final ConflictResolution resolution;

  const Conflict({
    required this.localEvent,
    required this.remoteEvent,
    required this.resolution,
  });
}

/// Çakışma çözümü
class ConflictResolution {
  final ConflictResolutionType type;
  final ExternalEvent? mergedEvent;
  final String? reason;

  const ConflictResolution({
    required this.type,
    this.mergedEvent,
    this.reason,
  });

  bool get keepLocal => type == ConflictResolutionType.keepLocal;
  bool get keepRemote => type == ConflictResolutionType.keepRemote;
  bool get isMerge => type == ConflictResolutionType.merge;
}

enum ConflictResolutionType { keepLocal, keepRemote, merge }

/// Senkronizasyon log kaydı
class SyncLog {
  final String id;
  final CalendarProvider provider;
  final String connectionId;
  final SyncResult result;
  final DateTime timestamp;

  const SyncLog({
    required this.id,
    required this.provider,
    required this.connectionId,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider.name,
    'connectionId': connectionId,
    'result': result.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}
