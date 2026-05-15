/// Session model for learning history.
/// Stores conversation, scene state, and educational progress.

class SessionModel {
  final String id;
  String title;
  String scene;
  List<ChatMessage> messages;
  int timelineStep;
  bool isBookmarked;
  DateTime createdAt;
  DateTime updatedAt;

  SessionModel({
    required this.id,
    required this.title,
    required this.scene,
    List<ChatMessage>? messages,
    this.timelineStep = 0,
    this.isBookmarked = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get previewText {
    if (messages.isEmpty) return 'No messages yet';
    final last = messages.last;
    return last.text.length > 80
        ? '${last.text.substring(0, 80)}...'
        : last.text;
  }

  String get timeAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'scene': scene,
        'timelineStep': timelineStep,
        'isBookmarked': isBookmarked,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      scene: json['scene'] ?? 'solar_system',
      timelineStep: json['timelineStep'] ?? 0,
      isBookmarked: json['isBookmarked'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List?)
              ?.map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          [],
    );
  }
}

/// Message types in a learning conversation.
enum MessageType {
  text,
  educationalCard,
  sceneCommand,
  factCard,
  aiResponse,
  thinking,
  visual,
  quiz,
  system,
  followUp,
}

/// A single message in a learning conversation.
class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  // AI-specific fields
  final String? emotion;
  final String? teachingStrategy;
  final String? visualScene;
  final bool visualTriggered;
  final String? followUpQuestion;
  final String? narrationText;
  final double? comprehensionScore;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.metadata,
    DateTime? timestamp,
    this.emotion,
    this.teachingStrategy,
    this.visualScene,
    this.visualTriggered = false,
    this.followUpQuestion,
    this.narrationText,
    this.comprehensionScore,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a thinking indicator message.
  factory ChatMessage.thinking() => ChatMessage(
        text: '',
        isUser: false,
        type: MessageType.thinking,
      );

  /// Create an AI response message from orchestrated response.
  factory ChatMessage.fromAI({
    required String text,
    String? emotion,
    String? strategy,
    String? visual,
    bool visualTriggered = false,
    String? followUp,
    String? narration,
    double? comprehension,
  }) =>
      ChatMessage(
        text: text,
        isUser: false,
        type: MessageType.aiResponse,
        emotion: emotion,
        teachingStrategy: strategy,
        visualScene: visual,
        visualTriggered: visualTriggered,
        followUpQuestion: followUp,
        narrationText: narration,
        comprehensionScore: comprehension,
      );

  /// Create a system message.
  factory ChatMessage.system(String text) => ChatMessage(
        text: text,
        isUser: false,
        type: MessageType.system,
      );

  /// Create a follow-up suggestion.
  factory ChatMessage.followUp(String question) => ChatMessage(
        text: question,
        isUser: false,
        type: MessageType.followUp,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'type': type.name,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
        'emotion': emotion,
        'teachingStrategy': teachingStrategy,
        'visualScene': visualScene,
        'visualTriggered': visualTriggered,
        'followUpQuestion': followUpQuestion,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      emotion: json['emotion'],
      teachingStrategy: json['teachingStrategy'],
      visualScene: json['visualScene'],
      visualTriggered: json['visualTriggered'] ?? false,
      followUpQuestion: json['followUpQuestion'],
    );
  }
}
