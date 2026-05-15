/// Kalvin AI — Memory Engine
///
/// Persistent storage for learner profiles, conversations,
/// comprehension history, and emotional history using Hive.

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'learner_profile.dart';

class MemoryEngine {
  static const String _profileBox = 'kalvin_profile';
  static const String _conversationBox = 'kalvin_conversations';
  static const String _sessionBox = 'kalvin_sessions';

  bool _initialized = false;

  /// Initialize Hive storage.
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox(_profileBox);
    await Hive.openBox(_conversationBox);
    await Hive.openBox(_sessionBox);
    _initialized = true;
  }

  // ── Learner Profile ──

  Future<void> saveLearnerProfile(LearnerProfile profile) async {
    final box = Hive.box(_profileBox);
    await box.put('profile', jsonEncode(profile.toJson()));
  }

  Future<LearnerProfile> loadLearnerProfile() async {
    final box = Hive.box(_profileBox);
    final raw = box.get('profile');
    if (raw == null) return LearnerProfile();
    try {
      final map = jsonDecode(raw as String);
      return LearnerProfile.fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return LearnerProfile();
    }
  }

  // ── Conversations ──

  Future<void> saveConversation(ConversationRecord record) async {
    final box = Hive.box(_conversationBox);
    final list = _getConversationList(box);
    list.add(record.toJson());
    // Keep last 100 conversations
    if (list.length > 100) {
      list.removeRange(0, list.length - 100);
    }
    await box.put('history', jsonEncode(list));
  }

  Future<List<ConversationRecord>> loadHistory({int limit = 20}) async {
    final box = Hive.box(_conversationBox);
    final list = _getConversationList(box);
    final records = list
        .map((e) => ConversationRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (records.length > limit) {
      return records.sublist(records.length - limit);
    }
    return records;
  }

  /// Get recent conversation as context string for prompts.
  Future<String> getRecentConversationContext({int turns = 5}) async {
    final history = await loadHistory(limit: turns);
    if (history.isEmpty) return 'No previous conversation.';

    final buffer = StringBuffer();
    for (final record in history) {
      buffer.writeln('User: ${record.userMessage}');
      buffer.writeln('Kalvin: ${record.aiResponse}');
      buffer.writeln();
    }
    return buffer.toString();
  }

  List<dynamic> _getConversationList(Box box) {
    final raw = box.get('history');
    if (raw == null) return [];
    try {
      return List.from(jsonDecode(raw as String));
    } catch (_) {
      return [];
    }
  }

  // ── Sessions ──

  Future<void> saveSession(SessionData session) async {
    final box = Hive.box(_sessionBox);
    final list = _getSessionList(box);
    list.add(session.toJson());
    if (list.length > 50) {
      list.removeRange(0, list.length - 50);
    }
    await box.put('sessions', jsonEncode(list));
  }

  Future<int> getSessionCount() async {
    final box = Hive.box(_sessionBox);
    return _getSessionList(box).length;
  }

  List<dynamic> _getSessionList(Box box) {
    final raw = box.get('sessions');
    if (raw == null) return [];
    try {
      return List.from(jsonDecode(raw as String));
    } catch (_) {
      return [];
    }
  }

  /// Clear all stored data.
  Future<void> clearAll() async {
    await Hive.box(_profileBox).clear();
    await Hive.box(_conversationBox).clear();
    await Hive.box(_sessionBox).clear();
  }
}

/// A single conversation turn.
class ConversationRecord {
  final String userMessage;
  final String aiResponse;
  final String emotion;
  final String topic;
  final DateTime timestamp;

  ConversationRecord({
    required this.userMessage,
    required this.aiResponse,
    this.emotion = 'neutral',
    this.topic = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'userMessage': userMessage,
        'aiResponse': aiResponse,
        'emotion': emotion,
        'topic': topic,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ConversationRecord.fromJson(Map<String, dynamic> json) {
    return ConversationRecord(
      userMessage: json['userMessage'] ?? '',
      aiResponse: json['aiResponse'] ?? '',
      emotion: json['emotion'] ?? 'neutral',
      topic: json['topic'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

/// A learning session summary.
class SessionData {
  final String topic;
  final int turnCount;
  final double avgComprehension;
  final String dominantEmotion;
  final DateTime startTime;
  final Duration duration;

  SessionData({
    required this.topic,
    required this.turnCount,
    required this.avgComprehension,
    this.dominantEmotion = 'neutral',
    DateTime? startTime,
    this.duration = Duration.zero,
  }) : startTime = startTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'turnCount': turnCount,
        'avgComprehension': avgComprehension,
        'dominantEmotion': dominantEmotion,
        'startTime': startTime.toIso8601String(),
        'durationMs': duration.inMilliseconds,
      };

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      topic: json['topic'] ?? '',
      turnCount: json['turnCount'] ?? 0,
      avgComprehension: (json['avgComprehension'] ?? 0.5).toDouble(),
      dominantEmotion: json['dominantEmotion'] ?? 'neutral',
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
    );
  }
}
