/// Kalvin AI — Life Companion Engine
///
/// Makes Kalvin feel alive with time-aware interactions,
/// emotional support, health reminders, and motivational nudges.
/// Kalvin behaves like a supportive friend, healthy companion,
/// and caring mentor — not just a teaching bot.

class LifeCompanionEngine {
  DateTime? _lastLunchReminder;
  DateTime? _lastDinnerReminder;
  DateTime? _lastSleepReminder;
  DateTime? _lastHydrationReminder;
  DateTime? _lastMotivation;
  int _consecutiveSessionMinutes = 0;
  DateTime _sessionStartTime = DateTime.now();

  /// Check if any life companion message should be shown.
  /// Returns null if no message is needed.
  LifeCompanionMessage? checkForMessage() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    // Sleep reminder (after 10 PM)
    if (hour >= 22 && _shouldRemind(_lastSleepReminder, 60)) {
      _lastSleepReminder = now;
      return LifeCompanionMessage(
        text: _getSleepMessage(hour),
        emotion: 'sleepy',
        type: CompanionMessageType.sleepReminder,
        priority: 3,
      );
    }

    // Lunch reminder (12 PM - 2 PM)
    if (hour >= 12 && hour < 14 && _shouldRemind(_lastLunchReminder, 90)) {
      _lastLunchReminder = now;
      return LifeCompanionMessage(
        text: _getLunchMessage(),
        emotion: 'caring',
        type: CompanionMessageType.lunchReminder,
        priority: 2,
      );
    }

    // Dinner reminder (7 PM - 9 PM)
    if (hour >= 19 && hour < 21 && _shouldRemind(_lastDinnerReminder, 90)) {
      _lastDinnerReminder = now;
      return LifeCompanionMessage(
        text: _getDinnerMessage(),
        emotion: 'caring',
        type: CompanionMessageType.dinnerReminder,
        priority: 2,
      );
    }

    // Hydration reminder (every 45 minutes of active use)
    _consecutiveSessionMinutes = now.difference(_sessionStartTime).inMinutes;
    if (_consecutiveSessionMinutes >= 45 && _shouldRemind(_lastHydrationReminder, 45)) {
      _lastHydrationReminder = now;
      return LifeCompanionMessage(
        text: _getHydrationMessage(),
        emotion: 'caring',
        type: CompanionMessageType.hydrationReminder,
        priority: 1,
      );
    }

    // Morning motivation (6 AM - 9 AM)
    if (hour >= 6 && hour < 9 && _shouldRemind(_lastMotivation, 180)) {
      _lastMotivation = now;
      return LifeCompanionMessage(
        text: _getMorningMessage(),
        emotion: 'encouraging',
        type: CompanionMessageType.motivation,
        priority: 1,
      );
    }

    // Break reminder (after 60 minutes of continuous use)
    if (_consecutiveSessionMinutes >= 60 && minute % 30 == 0) {
      return LifeCompanionMessage(
        text: _getBreakMessage(),
        emotion: 'gentle',
        type: CompanionMessageType.breakReminder,
        priority: 2,
      );
    }

    return null;
  }

  /// Get a contextual greeting based on time of day.
  String getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning! Ready to explore something new today? ☀️';
    if (hour >= 12 && hour < 17) return 'Good afternoon! Shall we learn something amazing? 🌤️';
    if (hour >= 17 && hour < 21) return 'Good evening! Perfect time for some discovery 🌅';
    return 'Hey, night owl! Still curious? I love that about you 🌙';
  }

  /// Get an encouragement message for frustrated learners.
  String getFrustrationSupport() {
    final messages = [
      "You're doing better than you think. Let's try a simpler way.",
      "It's okay to find this tricky. Even scientists get stuck sometimes!",
      "Let me explain this differently. Everyone learns in their own way.",
      "Don't worry, we'll figure this out together. One step at a time.",
      "You know what? The fact that you're trying is already amazing.",
    ];
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }

  /// Get a celebration message for achievement.
  String getCelebration() {
    final messages = [
      "That's awesome! You really understood that well! ✨",
      "Look at you go! You're learning so fast!",
      "Brilliant thinking! I'm really impressed.",
      "You nailed it! Your brain is working beautifully today.",
      "Wow, you figured that out! High five! 🙌",
    ];
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }

  /// Reset session timer (when app resumes or new session starts).
  void resetSessionTimer() {
    _sessionStartTime = DateTime.now();
    _consecutiveSessionMinutes = 0;
  }

  // ── Private message generators ──

  bool _shouldRemind(DateTime? lastReminder, int cooldownMinutes) {
    if (lastReminder == null) return true;
    return DateTime.now().difference(lastReminder).inMinutes >= cooldownMinutes;
  }

  String _getSleepMessage(int hour) {
    if (hour >= 23) {
      return "It's getting really late. Your brain remembers things better after good sleep. Time to rest? 🌙";
    }
    return "You've been learning a lot today. Sleep helps your brain remember things better. Maybe wrap up soon? 🌙";
  }

  String _getLunchMessage() {
    final messages = [
      "Did you have lunch today? A well-fed brain learns better! 🍚",
      "Hey, don't forget to eat lunch! Your brain needs fuel to keep learning 🍱",
      "Quick lunch break? Even scientists need to eat! We can continue after 🍽️",
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  String _getDinnerMessage() {
    final messages = [
      "It's dinner time! Take a break and enjoy your meal. I'll be here when you get back 🍛",
      "Have you had dinner yet? A good meal helps you think clearly tomorrow! 🥘",
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  String _getHydrationMessage() {
    final messages = [
      "Quick reminder — have some water! Staying hydrated helps your brain work better 💧",
      "Hey, drink some water! Your brain is 75% water, so keep it happy 💧",
      "Water break! A hydrated mind is a sharp mind 💧",
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  String _getMorningMessage() {
    final messages = [
      "Good morning! Ready to explore something new today? ☀️",
      "Rise and shine! What shall we discover today? 🌅",
      "Good morning! Your brain is fresh and ready to learn! ☀️",
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  String _getBreakMessage() {
    return "You've been learning for a while! Take a short break — stretch, look out the window, or take a deep breath. Your brain will thank you! 🌿";
  }
}

/// A life companion message with metadata.
class LifeCompanionMessage {
  final String text;
  final String emotion;
  final CompanionMessageType type;
  final int priority; // 1 = low, 2 = medium, 3 = high

  const LifeCompanionMessage({
    required this.text,
    required this.emotion,
    required this.type,
    required this.priority,
  });
}

/// Types of companion messages.
enum CompanionMessageType {
  lunchReminder,
  dinnerReminder,
  sleepReminder,
  hydrationReminder,
  breakReminder,
  motivation,
  celebration,
  frustrationSupport,
}
