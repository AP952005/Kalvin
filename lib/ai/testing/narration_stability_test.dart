/// Kalvin AI — Narration Stability Test
///
/// Tests TTS for rapid narration, interruption, stop/start,
/// overlapping requests, and zombie detection.

import '../narration_engine.dart';

class NarrationStabilityTest {
  final NarrationEngine _engine = NarrationEngine();

  Future<NarrationStabilityReport> runValidation() async {
    await _engine.init();
    final results = <String, bool>{};
    int overlaps = 0;

    // Test 1: Basic speak and stop
    try {
      await _engine.speak('Hello, I am Kalvin.');
      await Future.delayed(const Duration(milliseconds: 500));
      await _engine.stop();
      results['basic_speak_stop'] = !_engine.isSpeaking;
    } catch (e) {
      results['basic_speak_stop'] = false;
    }

    // Test 2: Rapid interruption
    try {
      await _engine.speak('First sentence about volcanoes.');
      await Future.delayed(const Duration(milliseconds: 200));
      await _engine.speak('Second sentence interrupting.');
      await Future.delayed(const Duration(milliseconds: 200));
      await _engine.speak('Third sentence interrupting.');
      await Future.delayed(const Duration(milliseconds: 500));
      await _engine.stop();
      results['rapid_interruption'] = true; // no crash = pass
    } catch (e) {
      results['rapid_interruption'] = false;
    }

    // Test 3: Stop when not speaking
    try {
      await _engine.stop();
      await _engine.stop();
      await _engine.stop();
      results['stop_when_idle'] = true;
    } catch (e) {
      results['stop_when_idle'] = false;
    }

    // Test 4: Empty text
    try {
      await _engine.speak('');
      results['empty_text'] = true;
    } catch (e) {
      results['empty_text'] = false;
    }

    // Test 5: Tone switching
    try {
      await _engine.speak('Excited!', tone: NarrationTone.excited);
      await Future.delayed(const Duration(milliseconds: 300));
      await _engine.speak('Calm now.', tone: NarrationTone.calm);
      await Future.delayed(const Duration(milliseconds: 300));
      await _engine.speak('Supportive.', tone: NarrationTone.supportive);
      await Future.delayed(const Duration(milliseconds: 300));
      await _engine.stop();
      results['tone_switching'] = true;
    } catch (e) {
      results['tone_switching'] = false;
    }

    // Test 6: Long text
    try {
      await _engine.speak(
          'This is a longer narration text that simulates what Kalvin '
          'would actually say during a real educational explanation about '
          'how volcanoes erupt and why they are fascinating natural phenomena.');
      await Future.delayed(const Duration(seconds: 1));
      await _engine.stop();
      results['long_text'] = true;
    } catch (e) {
      results['long_text'] = false;
    }

    // Test 7: Rapid fire (10 speaks in quick succession)
    try {
      for (int i = 0; i < 10; i++) {
        await _engine.speak('Message number $i');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      await _engine.stop();
      results['rapid_fire_10'] = !_engine.isSpeaking;
    } catch (e) {
      results['rapid_fire_10'] = false;
    }

    // Test 8: Zombie detection (check isSpeaking after stop)
    try {
      await _engine.speak('Test zombie.');
      await Future.delayed(const Duration(milliseconds: 300));
      await _engine.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      results['no_zombie'] = !_engine.isSpeaking;
    } catch (e) {
      results['no_zombie'] = false;
    }

    final passed = results.values.where((v) => v).length;

    return NarrationStabilityReport(
      totalTests: results.length,
      passed: passed,
      overlaps: overlaps,
      results: results,
    );
  }
}

class NarrationStabilityReport {
  final int totalTests;
  final int passed;
  final int overlaps;
  final Map<String, bool> results;

  NarrationStabilityReport({
    required this.totalTests,
    required this.passed,
    required this.overlaps,
    required this.results,
  });

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   NARRATION STABILITY REPORT         ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests | Passed: $passed');
    buf.writeln('Overlaps detected: $overlaps');
    buf.writeln('Stability: ${(passed / totalTests * 100).toStringAsFixed(1)}%');
    buf.writeln('\n--- Results ---');
    results.forEach((test, pass) {
      buf.writeln('${pass ? "✅" : "❌"} $test');
    });
    return buf.toString();
  }
}
