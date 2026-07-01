import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../domain/entities.dart';
import '../domain/models/child_homework.dart';
import '../domain/models/child_schedule.dart';
import '../domain/models/child_development_log.dart';

class HiveService {
  static T _safeEnum<T extends Enum>(List<T> values, dynamic index, T fallback) {
    if (index is! int) return fallback;
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  static late Box<String> _taskBox;
  static late Box<String> _transactionBox;
  static late Box<String> _chatBox;
  static late Box<String> _streakBox;
  static late Box<dynamic> _settingsBox;
  static late Box<String> _calendarBox;
  static late Box<String> _shoppingBox;
  static late Box<String> _familyBox;
  static late Box<String> _moodBox;

  static Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return await Hive.openBox<T>(name);
  }

  static Future<void> init() async {
    _taskBox = await _openBox<String>('tasks');
    _transactionBox = await _openBox<String>('transactions');
    _chatBox = await _openBox<String>('chat');
    _streakBox = await _openBox<String>('streaks');
    _settingsBox = await _openBox<dynamic>('settings');
    _calendarBox = await _openBox<String>('calendar');
    _shoppingBox = await _openBox<String>('shopping');
    _familyBox = await _openBox<String>('family');
    _moodBox = await _openBox<String>('moods');
  }

  // ========== TASKS ==========
  static Future<void> saveTasks(List<Task> tasks) async {
    final list = tasks.map((t) => {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'assignedTo': t.assignedTo,
      'status': t.status.index,
      'dueDate': t.dueDate?.toIso8601String(),
      'completedAt': t.completedAt?.toIso8601String(),
      'tags': t.tags,
      'streakCount': t.streakCount,
      'priority': t.priority,
    }).toList();
    await _taskBox.put('tasks', jsonEncode(list));
  }

  static List<Task> getTasks() {
    final raw = _taskBox.get('tasks');
    if (raw == null) return [];
    // ignore: unnecessary_cast
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw as String) as List<dynamic>);
    return list.map((t) => Task(
      id: t['id'] as String,
      title: t['title'] as String,
      description: t['description'] as String?,
      assignedTo: t['assignedTo'] as String,
      status: _safeEnum(TaskStatus.values, t['status'] as String, TaskStatus.pending),
      dueDate: t['dueDate'] != null ? DateTime.parse(t['dueDate'] as String) : null,
      completedAt: t['completedAt'] != null ? DateTime.parse(t['completedAt'] as String) : null,
      tags: List<String>.from(t['tags'] as List<dynamic>),
      streakCount: t['streakCount'] as int,
      priority: t['priority'] as String,
    )).toList();
  }

  // ========== TRANSACTIONS ==========
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final list = transactions.map((t) => {
      'id': t.id,
      'amount': t.amount,
      'currency': t.currency,
      'type': t.type.index,
      'category': t.category,
      'description': t.description,
      'createdBy': t.createdBy,
      'createdAt': t.createdAt.toIso8601String(),
      'attachments': t.attachments,
    }).toList();
    await _transactionBox.put('transactions', jsonEncode(list));
  }

  static List<Transaction> getTransactions() {
    final raw = _transactionBox.get('transactions');
    if (raw == null) return [];
    // ignore: unnecessary_cast
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw as String) as List<dynamic>);
    return list.map((t) => Transaction(
      id: t['id'] as String,
      amount: t['amount'] as double,
      currency: t['currency'] as String,
      type: _safeEnum(TransactionType.values, t['type'] as String, TransactionType.expense),
      category: t['category'] as String,
      description: t['description'] as String?,
      createdBy: t['createdBy'] as String,
      createdAt: DateTime.parse(t['createdAt'] as String),
      attachments: List<String>.from(t['attachments'] as List<dynamic>),
    )).toList();
  }

  // ========== CHAT ==========
  static Future<void> saveChatMessages(List<ChatMessage> messages) async {
    final list = messages.map((m) => {
      'id': m.id,
      'senderId': m.senderId,
      'senderName': m.senderName,
      'senderColor': m.senderColor.toARGB32(),
      'content': m.content,
      'createdAt': m.createdAt.toIso8601String(),
      'isRead': m.isRead,
      'type': m.type.index,
      'imageUrl': m.imageUrl,
      'audioUrl': m.audioUrl,
      'audioDuration': m.audioDuration,
      'reactions': m.reactions.map((r) => {'emoji': r.emoji, 'userIds': r.userIds}).toList(),
      'replyToId': m.replyToId,
      'replyToContent': m.replyToContent,
      'replyToSender': m.replyToSender,
      'isPinned': m.isPinned,
      'readCount': m.readCount,
    }).toList();
    await _chatBox.put('messages', jsonEncode(list));
  }

  static List<ChatMessage> getChatMessages() {
    final raw = _chatBox.get('messages');
    if (raw == null) return [];
    // ignore: unnecessary_cast
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw as String) as List<dynamic>);
    return list.map((m) => ChatMessage(
      id: m['id'] as String,
      senderId: m['senderId'] as String,
      senderName: m['senderName'] as String,
      senderColor: Color(m['senderColor'] as int),
      content: m['content'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      isRead: m['isRead'] as bool,
      type: _safeEnum(MessageType.values, m['type'] as String, MessageType.text),
      imageUrl: m['imageUrl'] as String?,
      audioUrl: m['audioUrl'] as String?,
      audioDuration: m['audioDuration'] as int?,
      reactions: (m['reactions'] as List<dynamic>).map((r) {
        final reaction = r as Map<String, dynamic>;
        return MessageReaction(
          emoji: reaction['emoji'] as String,
          userIds: List<String>.from(reaction['userIds'] as List<dynamic>),
        );
      }).toList(),
      replyToId: m['replyToId'] as String?,
      replyToContent: m['replyToContent'] as String?,
      replyToSender: m['replyToSender'] as String?,
      isPinned: m['isPinned'] as bool,
      readCount: m['readCount'] as int,
    )).toList();
  }

  // ========== STREAKS ==========
  static Future<void> saveStreaks(List<StreakEntry> streaks) async {
    final list = streaks.map((s) => {
      'id': s.id,
      'title': s.title,
      'date': s.date.toIso8601String(),
      'completed': s.completed,
      'note': s.note,
    }).toList();
    await _streakBox.put('streaks', jsonEncode(list));
  }

  static List<StreakEntry> getStreaks() {
    final raw = _streakBox.get('streaks');
    if (raw == null) return [];
    // ignore: unnecessary_cast
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw as String) as List<dynamic>);
    return list.map((s) => StreakEntry(
      id: s['id'] as String,
      title: s['title'] as String,
      date: DateTime.parse(s['date'] as String),
      completed: s['completed'] as bool,
      note: s['note'] as String?,
    )).toList();
  }

  // ========== SETTINGS ==========
  static Future<void> setSetting(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  static String? getSetting(String key) {
    final value = _settingsBox.get(key);
    if (value == null) return null;
    return value.toString();
  }

  static bool getBoolSetting(String key, {bool defaultValue = false}) {
    final value = _settingsBox.get(key);
    if (value == null) return defaultValue;
    if (value is bool) return value;
    return value.toString().toLowerCase() != 'false';
  }

  static Future<void> setBoolSetting(String key, bool value) async {
    await _settingsBox.put(key, value.toString());
  }

  static Future<void> setDoubleSetting(String key, double value) async {
    await _settingsBox.put(key, value);
  }

  static double? getDoubleSetting(String key) {
    final value = _settingsBox.get(key);
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    if (value is int) return value.toDouble();
    return null;
  }

  // ========== LOCATION ==========
  static Future<void> saveLocation(LocationModel location) async {
    await _settingsBox.put('savedLocation', jsonEncode(location.toJson()));
  }

  static LocationModel? getLocation() {
    final raw = _settingsBox.get('savedLocation');
    if (raw == null) return null;
    try {
      return LocationModel.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUseCurrentLocation(bool value) async {
    await _settingsBox.put('useCurrentLocation', value.toString());
  }

  static bool getUseCurrentLocation() {
    final raw = _settingsBox.get('useCurrentLocation');
    return raw != 'false';
  }

  // ========== ONBOARDING ==========
  static Future<void> setOnboardingCompleted(bool value) async {
    await _settingsBox.put('onboarding_completed', value.toString());
  }

  static bool getOnboardingCompleted() {
    final raw = _settingsBox.get('onboarding_completed');
    return raw == 'true';
  }

  // ========== CHILD HOMEWORKS ==========
  static Future<void> saveChildHomeworks(List<ChildHomework> list) async {
    final data = list.map((h) => h.toJson()).toList();
    await _settingsBox.put('child_homeworks', jsonEncode(data));
  }

  static List<ChildHomework> getChildHomeworks() {
    final raw = _settingsBox.get('child_homeworks');
    if (raw == null) return [];
    try {
      // ignore: unnecessary_cast
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw as String) as List<dynamic>);
      return list.map((e) => ChildHomework.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== CHILD SCHEDULES ==========
  static Future<void> saveChildSchedules(List<ChildSchedule> list) async {
    final data = list.map((s) => s.toJson()).toList();
    await _settingsBox.put('child_schedules', jsonEncode(data));
  }

  static List<ChildSchedule> getChildSchedules() {
    final raw = _settingsBox.get('child_schedules');
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw as String) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return list.map((e) => ChildSchedule.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== FAMILY SUGGESTIONS SETTINGS ==========
  static Future<void> setFamilySuggestionsEnabled(bool value) async {
    await _settingsBox.put('family_suggestions_enabled', value.toString());
  }

  static bool getFamilySuggestionsEnabled({bool defaultValue = true}) {
    final raw = _settingsBox.get('family_suggestions_enabled');
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    return raw.toString().toLowerCase() != 'false';
  }

  static Future<void> setFamilySuggestionsCategories(List<String> categories) async {
    await _settingsBox.put('family_suggestions_categories', jsonEncode(categories));
  }

  static List<String> getFamilySuggestionsCategories() {
    final raw = _settingsBox.get('family_suggestions_categories');
    if (raw == null) {
      return [
        'communication',
        'health',
        'education',
        'chore',
        'finance',
        'safety',
        'recipe',
        'social',
        'digital',
      ];
    }
    try {
      return List<String>.from(jsonDecode(raw as String) as List<dynamic>);
    } catch (_) {
      return [];
    }
  }

  static Future<void> setFamilySuggestionsPerDay(int count) async {
    await _settingsBox.put('family_suggestions_per_day', count.toString());
  }

  static int getFamilySuggestionsPerDay({int defaultValue = 5}) {
    final raw = _settingsBox.get('family_suggestions_per_day');
    if (raw == null) return defaultValue;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? defaultValue;
  }

  static Future<void> setFamilySuggestionsNotifications(bool value) async {
    await _settingsBox.put('family_suggestions_notifications', value.toString());
  }

  static bool getFamilySuggestionsNotifications({bool defaultValue = true}) {
    final raw = _settingsBox.get('family_suggestions_notifications');
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    return raw.toString().toLowerCase() != 'false';
  }

  // ========== SHOWN SUGGESTION IDS (Daily rotation) ==========
  static Future<void> saveShownSuggestionIds(List<String> ids) async {
    await _settingsBox.put('shown_suggestion_ids', jsonEncode(ids));
  }

  static List<String> getShownSuggestionIds() {
    final raw = _settingsBox.get('shown_suggestion_ids');
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw as String) as List<dynamic>);
    } catch (_) {
      return [];
    }
  }

  static Future<void> addShownSuggestionIds(List<String> ids) async {
    final current = getShownSuggestionIds();
    final updated = {...current, ...ids}.toList();
    // Keep only last 90 days worth (roughly 90 * 5 = 450 ids)
    if (updated.length > 450) {
      updated.removeRange(0, updated.length - 450);
    }
    await saveShownSuggestionIds(updated);
  }

  // ========== CHILD DEVELOPMENT LOGS ==========
  static Future<void> saveChildDevLogs(List<ChildDevelopmentLog> list) async {
    final data = list.map((l) => l.toJson()).toList();
    await _settingsBox.put('child_dev_logs', jsonEncode(data));
  }

  static List<ChildDevelopmentLog> getChildDevLogs() {
    final raw = _settingsBox.get('child_dev_logs');
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw as String) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return list.map((e) => ChildDevelopmentLog.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== CALENDAR ==========
  static Future<void> saveCalendarEvents(List<CalendarEvent> list) async {
    final data = list.map((e) => e.toJson()).toList();
    await _calendarBox.put('events', jsonEncode(data));
  }

  static List<CalendarEvent> getCalendarEvents() {
    final raw = _calendarBox.get('events');
    if (raw == null) return [];
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
      return list.map((e) => CalendarEvent.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== SHOPPING ==========
  static Future<void> saveShoppingItems(List<ShoppingItem> list) async {
    final data = list.map((e) => e.toJson()).toList();
    await _shoppingBox.put('items', jsonEncode(data));
  }

  static List<ShoppingItem> getShoppingItems() {
    final raw = _shoppingBox.get('items');
    if (raw == null) return [];
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
      return list.map((e) => ShoppingItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== FAMILY MEMBERS ==========
  static Future<void> saveFamilyMembers(List<FamilyMember> list) async {
    final data = list.map((e) => e.toJson()).toList();
    await _familyBox.put('members', jsonEncode(data));
  }

  static List<FamilyMember> getFamilyMembers() {
    final raw = _familyBox.get('members');
    if (raw == null) return [];
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
      return list.map((e) => FamilyMember.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== MOOD ==========
  static Future<void> saveMoodEntries(List<MoodEntry> list) async {
    final data = list.map((e) => e.toJson()).toList();
    await _moodBox.put('entries', jsonEncode(data));
  }

  static List<MoodEntry> getMoodEntries() {
    final raw = _moodBox.get('entries');
    if (raw == null) return [];
    try {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List<dynamic>);
      return list.map((e) => MoodEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ========== GENERIC JSON CACHE ==========
  // Used by family_health_screen, subscription_screen, child_development_screen

  static Future<void> saveJson(String key, dynamic data) async {
    await _settingsBox.put('cache_$key', jsonEncode(data));
  }

  static dynamic loadJson(String key) {
    final raw = _settingsBox.get('cache_$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw as String);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteJson(String key) async {
    await _settingsBox.delete('cache_$key');
  }
}
