/// Kalvin AI — Prompt Validation Test
///
/// Tests whether the LLM obeys strict JSON output format.
/// Detects markdown wrapping, broken JSON, missing fields,
/// and hallucinated text outside JSON.

import 'dart:convert';
import '../llama_service.dart';
import '../prompt_builder.dart';
import '../response_parser.dart';
import 'orchestration_logger.dart';

class PromptValidationTest {
  final LlamaService _llama;
  final ResponseParser _parser = ResponseParser();
  final OrchestrationLogger _logger = OrchestrationLogger();

  PromptValidationTest(this._llama);

  static const _testPrompts = [
    'What is the sun?', 'Explain gravity', 'How do volcanoes work?',
    'What is water?', 'Why is the sky blue?', 'What is DNA?',
    'How do plants make food?', 'What is electricity?',
    'Explain the moon', 'What causes earthquakes?',
    'What is temperature?', 'How do magnets work?',
    'What is oxygen?', 'Explain photosynthesis', 'What are stars?',
    'How does rain form?', 'What is an atom?', 'Explain friction',
    'What is sound?', 'How do eyes work?',
  ];

  Future<PromptValidationReport> runValidation({int count = 20}) async {
    final results = <_PromptResult>[];
    int validJson = 0;
    int recoveredJson = 0;
    int failedJson = 0;
    int markdownWrapped = 0;
    int missingFields = 0;

    final promptBuilder = PromptBuilder();
    await promptBuilder.init();

    final limit = count.clamp(1, _testPrompts.length);

    for (int i = 0; i < limit; i++) {
      final input = _testPrompts[i];
      _logger.info('PromptValidation', 'Testing: "$input"');

      try {
        final prompt = promptBuilder.buildQuick(input);
        final raw = await _llama.generateResponse(prompt);

        // Analyze raw output
        final hasMarkdown = raw.contains('```');
        if (hasMarkdown) markdownWrapped++;

        final hasExtraText = !raw.trimLeft().startsWith('{');

        // Try parsing
        final parsed = _parser.parse(raw);
        final isCleanJson = _isCleanJson(raw);
        final missing = _checkMissingFields(raw);
        if (missing > 0) missingFields += missing;

        if (isCleanJson) {
          validJson++;
        } else if (parsed.response.isNotEmpty &&
            parsed.response != 'Let me think about that differently. Can you ask again?') {
          recoveredJson++;
        } else {
          failedJson++;
        }

        results.add(_PromptResult(
          input: input,
          rawOutput: raw.length > 200 ? '${raw.substring(0, 200)}...' : raw,
          cleanJson: isCleanJson,
          recovered: !isCleanJson && parsed.response.isNotEmpty,
          hasMarkdown: hasMarkdown,
          hasExtraText: hasExtraText,
          missingFields: missing,
        ));
      } catch (e) {
        failedJson++;
        results.add(_PromptResult(
          input: input,
          rawOutput: 'ERROR: $e',
          cleanJson: false,
          recovered: false,
          hasMarkdown: false,
          hasExtraText: false,
          missingFields: 9,
        ));
        _logger.error('PromptValidation', 'Failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    return PromptValidationReport(
      totalTests: limit,
      validJson: validJson,
      recoveredJson: recoveredJson,
      failedJson: failedJson,
      markdownWrapped: markdownWrapped,
      totalMissingFields: missingFields,
      results: results,
    );
  }

  bool _isCleanJson(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return false;
    try {
      final decoded = jsonDecode(trimmed);
      return decoded is Map<String, dynamic>;
    } catch (_) {
      return false;
    }
  }

  int _checkMissingFields(String raw) {
    const required = [
      'response', 'narration', 'emotion', 'teaching_strategy',
      'visual_required', 'visual_scene', 'follow_up_question',
      'comprehension_check',
    ];
    int missing = 0;
    for (final field in required) {
      if (!raw.contains('"$field"')) missing++;
    }
    return missing;
  }
}

class _PromptResult {
  final String input;
  final String rawOutput;
  final bool cleanJson;
  final bool recovered;
  final bool hasMarkdown;
  final bool hasExtraText;
  final int missingFields;

  _PromptResult({
    required this.input,
    required this.rawOutput,
    required this.cleanJson,
    required this.recovered,
    required this.hasMarkdown,
    required this.hasExtraText,
    required this.missingFields,
  });
}

class PromptValidationReport {
  final int totalTests;
  final int validJson;
  final int recoveredJson;
  final int failedJson;
  final int markdownWrapped;
  final int totalMissingFields;
  final List<_PromptResult> results;

  PromptValidationReport({
    required this.totalTests,
    required this.validJson,
    required this.recoveredJson,
    required this.failedJson,
    required this.markdownWrapped,
    required this.totalMissingFields,
    required this.results,
  });

  double get complianceRate =>
      totalTests > 0 ? (validJson + recoveredJson) / totalTests : 0;

  String generateReport() {
    final buf = StringBuffer();
    buf.writeln('╔══════════════════════════════════════╗');
    buf.writeln('║   PROMPT VALIDATION REPORT           ║');
    buf.writeln('╚══════════════════════════════════════╝');
    buf.writeln('Tests: $totalTests');
    buf.writeln('Clean JSON: $validJson');
    buf.writeln('Recovered JSON: $recoveredJson');
    buf.writeln('Failed: $failedJson');
    buf.writeln('Markdown wrapped: $markdownWrapped');
    buf.writeln('Missing fields total: $totalMissingFields');
    buf.writeln('Compliance: ${(complianceRate * 100).toStringAsFixed(1)}%');
    return buf.toString();
  }
}
