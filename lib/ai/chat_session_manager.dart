/// Kalvin AI — Chat Session Manager
///
/// Production-grade chat persistence using Hive.
/// Supports new chat creation, session restoration,
/// auto-generated titles, timestamps, and sorting.

import 'package:hive_flutter/hive_flutter.dart';

/// A single chat session with messages, metadata, and progress.
class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime lastActiveAt;
  final List<ChatSessionMessage> messages;
  String emotion;
  double comprehensionScore;
  List<String> topicsCovered;
  List<String> visualsUsed;

  ChatSession({
    required this.id,
    this.title = 'New Conversation',
    DateTime? createdAt,
    DateTime? lastActiveAt,
    List<ChatSessionMessage>? messages,
    this.emotion = 'neutral',
    this.comprehensionScore = 0.5,
    List<String>? topicsCovered,
    List<String>? visualsUsed,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now(),
        messages = messages ?? [],
        topicsCovered = topicsCovered ?? [],
        visualsUsed = visualsUsed ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'emotion': emotion,
        'comprehensionScore': comprehensionScore,
        'topicsCovered': topicsCovered,
        'visualsUsed': visualsUsed,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastActiveAt:
          DateTime.tryParse(json['lastActiveAt'] ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List?)
              ?.map((m) => ChatSessionMessage.fromJson(
                  Map<String, dynamic>.from(m as Map)))
              .toList() ??
          [],
      emotion: json['emotion'] ?? 'neutral',
      comprehensionScore:
          (json['comprehensionScore'] as num?)?.toDouble() ?? 0.5,
      topicsCovered: List<String>.from(json['topicsCovered'] ?? []),
      visualsUsed: List<String>.from(json['visualsUsed'] ?? []),
    );
  }
}

/// Individual message in a session.
class ChatSessionMessage {
  final String text;
  final bool isUser;
  final String type; // 'user', 'ai', 'system', 'followUp'
  final DateTime timestamp;
  final String? emotion;
  final String? topic;

  ChatSessionMessage({
    required this.text,
    required this.isUser,
    this.type = 'user',
    DateTime? timestamp,
    this.emotion,
    this.topic,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'emotion': emotion,
        'topic': topic,
      };

  factory ChatSessionMessage.fromJson(Map<String, dynamic> json) {
    return ChatSessionMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      type: json['type'] ?? 'user',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      emotion: json['emotion'],
      topic: json['topic'],
    );
  }
}

/// Manages persistent chat sessions using Hive.
class ChatSessionManager {
  static const String _boxName = 'kalvin_chat_sessions';
  Box? _box;
  bool _initialized = false;

  /// Initialize Hive storage.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _box = await Hive.openBox(_boxName);
      _initialized = true;
    } catch (e) {
      // If box is corrupted, delete and recreate
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _box = await Hive.openBox(_boxName);
        _initialized = true;
      } catch (_) {
        _initialized = false;
      }
    }
  }

  /// Create a new chat session.
  ChatSession createSession({String title = 'New Conversation'}) {
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    _saveSession(session);
    return session;
  }

  /// Save a session to Hive.
  Future<void> _saveSession(ChatSession session) async {
    if (!_initialized || _box == null) return;
    try {
      await _box!.put(session.id, session.toJson());
    } catch (_) {}
  }

  /// Save/update a session.
  Future<void> saveSession(ChatSession session) async {
    session.lastActiveAt = DateTime.now();
    await _saveSession(session);
  }

  /// Add a message to a session and save.
  Future<void> addMessage(
    ChatSession session,
    ChatSessionMessage message,
  ) async {
    session.messages.add(message);
    session.lastActiveAt = DateTime.now();
    await _saveSession(session);
  }

  /// Get all sessions sorted by last active (newest first).
  List<ChatSession> getAllSessions() {
    if (!_initialized || _box == null) return [];

    try {
      final sessions = <ChatSession>[];
      for (final key in _box!.keys) {
        try {
          final data = _box!.get(key);
          if (data != null) {
            sessions.add(
              ChatSession.fromJson(Map<String, dynamic>.from(data as Map)),
            );
          }
        } catch (_) {
          // Skip corrupted sessions
        }
      }

      // Sort by last active, newest first
      sessions.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  /// Get recent sessions (for home screen).
  List<ChatSession> getRecentSessions({int limit = 5}) {
    return getAllSessions().take(limit).toList();
  }

  /// Load a specific session.
  ChatSession? loadSession(String sessionId) {
    if (!_initialized || _box == null) return null;
    try {
      final data = _box!.get(sessionId);
      if (data != null) {
        return ChatSession.fromJson(Map<String, dynamic>.from(data as Map));
      }
    } catch (_) {}
    return null;
  }

  /// Delete a session.
  Future<void> deleteSession(String sessionId) async {
    if (!_initialized || _box == null) return;
    try {
      await _box!.delete(sessionId);
    } catch (_) {}
  }

  /// Delete all sessions.
  Future<void> clearAll() async {
    if (!_initialized || _box == null) return;
    try {
      await _box!.clear();
    } catch (_) {}
  }

  /// Update session title.
  Future<void> updateTitle(ChatSession session, String title) async {
    session.title = title;
    await _saveSession(session);
  }

  /// Get total session count.
  int get sessionCount {
    if (!_initialized || _box == null) return 0;
    return _box!.length;
  }
}
