import 'package:flutter/material.dart';

export 'models/today_summary.dart';
export 'models/hub_event.dart';
export 'models/hub_task.dart';
export 'models/family_mood.dart';

enum HubCardType { tasks, streak, calendar, budget, smartReminders, routines, crashDetection, locationTracking, sos, contacts, gallery, documents, kitchen, education, shopping, childDev }
enum TaskStatus { pending, inProgress, completed, cancelled }
enum MemberRole { admin, parent, teen, child, elder, guest, baby }
enum EventCategory { appointment, birthday, school, activity, work, family, travel, other }
enum TransactionType { income, expense }
enum ShoppingCategory { grocery, pharmacy, stationery, household, other }
enum MessageType { text, image, audio, location, event, system }

class FamilyMember {
  final String id;
  final String name;
  final String initial;
  final Color color;
  final String? avatarUrl;
  final MemberRole role;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? joinedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.initial,
    required this.color,
    this.avatarUrl,
    required this.role,
    this.isOnline = false,
    this.lastSeen,
    this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initial': initial,
    'color': color.toARGB32(),
    'avatarUrl': avatarUrl,
    'role': role.index,
    'isOnline': isOnline,
    'lastSeen': lastSeen?.toIso8601String(),
    'joinedAt': joinedAt?.toIso8601String(),
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    name: json['name'] as String,
    initial: json['initial'] as String,
    color: Color(json['color'] as int),
    avatarUrl: json['avatarUrl'] as String?,
    role: MemberRole.values[json['role'] as int],
    isOnline: json['isOnline'] as bool? ?? false,
    lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
    joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt'] as String) : null,
  );
}

class HubCard {
  final String id;
  final HubCardType type;
  final String title;
  final String subtitle;
  final double progress;
  final List<Color> gradient;
  final IconData icon;
  final DateTime updatedAt;

  const HubCard({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.gradient,
    required this.icon,
    required this.updatedAt,
  });
}

class Task {
  final String id;
  final String title;
  final String? description;
  final String assignedTo;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> tags;
  final int streakCount;
  final String priority;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    this.status = TaskStatus.pending,
    this.dueDate,
    this.completedAt,
    this.tags = const [],
    this.streakCount = 0,
    this.priority = 'medium',
  });

  Task copyWith({
    String? title,
    String? description,
    String? assignedTo,
    String? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? completedAt,
    int? streakCount,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      tags: tags,
      streakCount: streakCount ?? this.streakCount,
      priority: priority ?? this.priority,
    );
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? description;
  final List<String> attendees;
  final EventCategory category;
  final String? recurrenceRule;
  final Color color;
  final bool isAllDay;
  final List<int> reminders;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.location,
    this.description,
    this.attendees = const [],
    this.category = EventCategory.family,
    this.recurrenceRule,
    this.color = Colors.blue,
    this.isAllDay = false,
    this.reminders = const [],
  });

  CalendarEvent copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    String? location,
    String? description,
    List<String>? attendees,
    EventCategory? category,
    String? recurrenceRule,
    Color? color,
    bool? isAllDay,
    List<int>? reminders,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      description: description ?? this.description,
      attendees: attendees ?? this.attendees,
      category: category ?? this.category,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'location': location,
    'description': description,
    'attendees': attendees,
    'category': category.index,
    'recurrenceRule': recurrenceRule,
    'color': color.toARGB32(),
    'isAllDay': isAllDay,
    'reminders': reminders,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    location: json['location'] as String?,
    description: json['description'] as String?,
    attendees: List<String>.from((json['attendees'] as List<dynamic>?) ?? []),
    category: EventCategory.values[json['category'] as int],
    recurrenceRule: json['recurrenceRule'] as String?,
    color: Color(json['color'] as int),
    isAllDay: json['isAllDay'] as bool? ?? false,
    reminders: List<int>.from((json['reminders'] as List<dynamic>?) ?? []),
  );
}

class Transaction {
  final String id;
  final double amount;
  final String currency;
  final TransactionType type;
  final String category;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final List<String> attachments;

  const Transaction({
    required this.id,
    required this.amount,
    this.currency = 'EUR',
    required this.type,
    required this.category,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.attachments = const [],
  });

  Transaction copyWith({
    double? amount,
    String? category,
    String? description,
    List<String>? attachments,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      currency: currency,
      type: type,
      category: category ?? this.category,
      description: description ?? this.description,
      createdBy: createdBy,
      createdAt: createdAt,
      attachments: attachments ?? this.attachments,
    );
  }
}

class Budget {
  final String id;
  final double totalAmount;
  final double spentAmount;
  final String currency;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final Map<String, double> categoryLimits;

  const Budget({
    required this.id,
    required this.totalAmount,
    required this.spentAmount,
    this.currency = 'EUR',
    this.periodStart,
    this.periodEnd,
    this.categoryLimits = const {},
  });
}

class ShoppingItem {
  final String id;
  final String name;
  final String? quantity;
  final ShoppingCategory category;
  final String requestedBy;
  final bool isCompleted;
  final String? completedBy;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    this.category = ShoppingCategory.grocery,
    required this.requestedBy,
    this.isCompleted = false,
    this.completedBy,
  });

  ShoppingItem copyWith({bool? isCompleted, String? completedBy}) {
    return ShoppingItem(
      id: id,
      name: name,
      quantity: quantity,
      category: category,
      requestedBy: requestedBy,
      isCompleted: isCompleted ?? this.isCompleted,
      completedBy: completedBy ?? this.completedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'category': category.index,
    'requestedBy': requestedBy,
    'isCompleted': isCompleted,
    'completedBy': completedBy,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as String?,
    category: ShoppingCategory.values[json['category'] as int],
    requestedBy: json['requestedBy'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedBy: json['completedBy'] as String?,
  );
}

class Activity {
  final String id;
  final String actorName;
  final String action;
  final String target;
  final DateTime createdAt;
  final Color actorColor;

  const Activity({
    required this.id,
    required this.actorName,
    required this.action,
    required this.target,
    required this.createdAt,
    required this.actorColor,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final Color senderColor;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final MessageType type;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDuration;
  final List<MessageReaction> reactions;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSender;
  final bool isPinned;
  final int readCount;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderColor,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.audioUrl,
    this.audioDuration,
    this.reactions = const [],
    this.replyToId,
    this.replyToContent,
    this.replyToSender,
    this.isPinned = false,
    this.readCount = 0,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    List<MessageReaction>? reactions,
    bool? isPinned,
    int? readCount,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId,
      senderName: senderName,
      senderColor: senderColor,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSender: replyToSender,
      isPinned: isPinned ?? this.isPinned,
      readCount: readCount ?? this.readCount,
    );
  }
}

class MessageReaction {
  final String emoji;
  final List<String> userIds;

  const MessageReaction({
    required this.emoji,
    required this.userIds,
  });

  int get count => userIds.length;
}

class MoodEntry {
  final String id;
  final String userId;
  final String familyId;
  final String emoji;
  final String? note;
  final DateTime createdAt;

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.emoji,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'familyId': familyId,
    'emoji': emoji,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
    id: json['id'] as String,
    userId: json['userId'] as String,
    familyId: json['familyId'] as String,
    emoji: json['emoji'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class StreakEntry {
  final String id;
  final String title;
  final DateTime date;
  final bool completed;
  final String? note;

  const StreakEntry({
    required this.id,
    required this.title,
    required this.date,
    this.completed = true,
    this.note,
  });
}

class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String country;
  final String fullAddress;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.country,
    required this.fullAddress,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'city': city,
    'country': country,
    'fullAddress': fullAddress,
  };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    address: json['address'] as String,
    city: json['city'] as String,
    country: json['country'] as String,
    fullAddress: json['fullAddress'] as String,
  );
}
