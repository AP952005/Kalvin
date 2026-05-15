/// Kalvin AI — Memory Validation Test
///
/// Tests Hive persistence: profile save/load, conversation
/// history restore, interests persistence, and data integrity.

import '../memory_engine.dart';
import '../learner_profile.dart';

class MemoryValidationTest {
  final MemoryEngine _memory = MemoryEngine();

  Future<MemoryValidationReport> runValidation() async {
    await _memory.init();
    final results = <String, bool>{};

    // Test 1: Save and load learner profile
    try {
      final profile = LearnerProfile();
      profile.updateInterest('volcanoes', delta: 0.5);
      profile.updateFamiliarity('nature', 0.8);
      profile.updateComprehension('gravity', 0.3);
      profile.vocabularyLevel = 3;
      profile.totalSessions = 5;

      await _memory.saveLearnerProfile(profile);
      final loaded = await _memory.loadLearnerProfile();

      results['profile_save_load'] =
          loaded.interests['volcanoes'] != null &&
          loaded.familiarityMap['nature'] == 0.8 &&
          loaded.vocabularyLevel == 3 &&
          loaded.totalSessions == 5;
    } catch (e) {
      results['profile_save_load'] = false;
    }

    // Test 2: Conversation save and restore
    try {
      await _memory.saveConversation(ConversationRecord(
        userMessage: 'What is a volcano?',
        aiResponse: 'A volcano is an opening in the earth.',
        emotion: 'curious',
        topic: 'volcano',
      ));
      await _memory.saveConversation(ConversationRecord(
        userMessage: 'How does rain form?',
        aiResponse: 'Rain forms through evaporation.',
        emotion: 'curious',
        topic: 'water_cycle',
      ));

      final history = await _memory.loadHistory(limit: 10);
      results['conversation_persistence'] = history.length >= 2;
    } catch (e) {
      results['conversation_persistence'] = false;
    }

    // Test 3: Conversation context string
    try {
      final context = await _memory.getRecentConversationContext(turns: 5);
      results['context_generation'] =
          context.contains('User:') && context.contains('Kalvin:');
    } catch (e) {
      results['context_generation'] = false;
    }

    // Test 4: Session save
    try {
      await _memory.saveSession(SessionData(
        topic: 'volcano',
        turnCount: 10,
        avgComprehension: 0.7,
        dominantEmotion: 'curious',
      ));
      final count = await _memory.getSessionCount();
      results['session_persistence'] = count >= 1;
    } catch (e) {
      results['session_persistence'] = false;
    }

    // Test 5: Profile comprehension scores persist
    try {
      final loaded = await _memory.loadLearnerProfile();
      results['comprehension_persistence'] =
          loaded.comprehensionScores.containsKey('gravity');
    } catch (e) {
      results['comprehension_persistence'] = false;
    }

    // Test 6: Familiarity map restore
    try {
      final loaded = await _memory.loadLearnerProfile();
      results['familiarity_persistence'] =
          loaded.familiarityMap.isNotEmpty &&
          loaded.familiarityMap['nature'] == 0.8;
    } catch (e) {
      results['familiarity_persistence'] = false;
    }

    final passed = results.values.where((v) => v).length;

    return MemoryValidationReport(
      totalTests: results.length,
      passed: passed,
      results: results,
    );
  }
}

class MemoryValidationReport {
  final int totalTests;
  final int passed;
  final Map<String, bool> results;

  MemoryValidationReport({
    required this.totalTests,
    required this.passed,
    required this.results,
  });

  double get integrity => totalTests > 0 ? passed / totalTests : 0;

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   MEMORY VALIDATION REPORT           ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests | Passed: $passed');
    buf.writeln('Integrity: ${(integrity * 100).toStringAsFixed(1)}%');
    buf.writeln('\n--- Results ---');
    results.forEach((test, pass) {
      buf.writeln('${pass ? "✅" : "❌"} $test');
    });
    return buf.toString();
  }
}
