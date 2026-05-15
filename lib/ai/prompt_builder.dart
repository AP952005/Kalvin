/// Kalvin AI — Prompt Builder (Gemma 2B Optimized)
///
/// Builds SHORT, SIMPLE prompts that Gemma 2B can handle.
/// No JSON instructions. No complex schemas. Just natural conversation.

import 'package:flutter/services.dart' show rootBundle;

class PromptBuilder {
  String? _template;

  static const String _fallback = '''You are Kalvin, a warm learning friend for students.
Rules: Be concise. Explain simply. No markdown. No JSON. Never repeat greetings.

Student: {input}
Kalvin:''';

  Future<void> init() async {
    try {
      _template = await rootBundle.loadString('assets/prompts/system_prompt.txt');
    } catch (_) {
      _template = _fallback;
    }
  }

  /// Build a simple prompt with minimal context.
  Future<String> buildSimple({
    required String userInput,
    String history = '',
    String topic = '',
  }) async {
    if (_template == null) await init();
    final template = _template ?? _fallback;

    // Build minimal history (last 3 turns only)
    var historyBlock = history;
    if (historyBlock.isEmpty) {
      historyBlock = '(This is the start of a new conversation.)';
    }

    return template
        .replaceAll('{history}', historyBlock)
        .replaceAll('{input}', userInput);
  }
}
