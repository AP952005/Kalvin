/// Kalvin AI — AI Debug Dashboard
///
/// Full developer debug widget showing real-time orchestration
/// diagnostics. NOT for production UI.

import 'package:flutter/material.dart';
import '../learning_orchestrator.dart';
import '../emotion_engine.dart';
import 'orchestration_logger.dart';
import 'orchestrator_test_runner.dart';
import 'stress_test_runner.dart';
import 'modality_validation_test.dart';
import 'emotional_response_test.dart';
import 'visual_trigger_test.dart';
import 'narration_stability_test.dart';
import 'memory_validation_test.dart';
import 'offline_validation_test.dart';
import 'comprehension_test_runner.dart';

class AIDebugDashboard extends StatefulWidget {
  const AIDebugDashboard({super.key});

  @override
  State<AIDebugDashboard> createState() => _AIDebugDashboardState();
}

class _AIDebugDashboardState extends State<AIDebugDashboard> {
  final LearningOrchestrator _orchestrator = LearningOrchestrator();
  final OrchestrationLogger _logger = OrchestrationLogger();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  bool _initialized = false;
  bool _running = false;
  String _status = 'Not initialized';
  String _lastEmotion = '-';
  String _lastModality = '-';
  double _lastComprehension = 0;
  String _lastVisual = '-';
  int _latencyMs = 0;
  bool _llmAvailable = false;

  final List<String> _logLines = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _log('Initializing orchestrator...');
    try {
      await _orchestrator.init();
      _llmAvailable = await _orchestrator.isLLMAvailable();
      setState(() {
        _initialized = true;
        _status = _llmAvailable
            ? '✅ Ready (LLM online)'
            : '⚠️ Ready (LLM offline)';
      });
      _log('Initialized. LLM: $_llmAvailable');
    } catch (e) {
      setState(() => _status = '❌ Init failed: $e');
      _log('ERROR: $e');
    }
  }

  void _log(String msg) {
    setState(() {
      _logLines.add('[${DateTime.now().toString().substring(11, 19)}] $msg');
      if (_logLines.length > 100) _logLines.removeAt(0);
    });
  }

  Future<void> _sendTestMessage() async {
    final input = _inputController.text.trim();
    if (input.isEmpty || !_initialized || _running) return;

    setState(() => _running = true);
    _log('→ "$input"');

    final sw = Stopwatch()..start();
    try {
      final response = await _orchestrator.processUserInput(input);
      sw.stop();
      await _orchestrator.stopNarration();

      setState(() {
        _lastEmotion = response.emotionState.name;
        _lastModality = response.selectedModality.name;
        _lastComprehension = response.comprehensionScore;
        _lastVisual = response.learningResponse.visualRequired
            ? response.learningResponse.visualScene
            : 'none';
        _latencyMs = sw.elapsedMilliseconds;
      });

      _log('← ${response.learningResponse.response.length > 80 ? response.learningResponse.response.substring(0, 80) + "..." : response.learningResponse.response}');
      _log('  Emotion: $_lastEmotion | Modality: $_lastModality | ${_latencyMs}ms');
    } catch (e) {
      _log('ERROR: $e');
    }

    setState(() => _running = false);
    _inputController.clear();
  }

  Future<void> _runTest(String name, Future<String> Function() test) async {
    setState(() => _running = true);
    _log('Running $name...');
    try {
      final report = await test();
      _log('$name complete:');
      for (final line in report.split('\n')) {
        _log('  $line');
      }
    } catch (e) {
      _log('$name FAILED: $e');
    }
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('AI Debug Dashboard',
            style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
        backgroundColor: const Color(0xFF161B22),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => setState(() => _logLines.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF161B22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $_status',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
                const SizedBox(height: 8),
                _buildMetricsRow(),
              ],
            ),
          ),

          // Log output
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _logLines.length,
              itemBuilder: (_, i) {
                final line = _logLines[i];
                Color color = Colors.grey.shade400;
                if (line.contains('ERROR')) color = Colors.redAccent;
                if (line.contains('✅')) color = Colors.greenAccent;
                if (line.contains('❌')) color = Colors.redAccent;
                if (line.startsWith('[') && line.contains('→')) {
                  color = Colors.cyanAccent;
                }
                return Text(line,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: color));
              },
            ),
          ),

          // Test buttons
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _testBtn('Emotion', () async {
                    final r = await EmotionalResponseTest().runValidation();
                    return r.generateReport();
                  }),
                  _testBtn('Modality', () async {
                    final r = await ModalityValidationTest().runValidation();
                    return r.generateReport();
                  }),
                  _testBtn('Visual', () async {
                    final r = await VisualTriggerTest().runValidation();
                    return r.generateReport();
                  }),
                  _testBtn('Memory', () async {
                    final r = await MemoryValidationTest().runValidation();
                    return r.generateReport();
                  }),
                  _testBtn('Narration', () async {
                    final r = await NarrationStabilityTest().runValidation();
                    return r.generateReport();
                  }),
                  _testBtn('Offline', () async {
                    final r = await OfflineValidationTest().runValidation();
                    return r.generateReport();
                  }),
                  _testBtn('Full AI', () async {
                    final r = await OrchestratorTestRunner(_orchestrator).runAllTests();
                    return r.generateReport();
                  }),
                  _testBtn('Comprehension', () async {
                    final r = await ComprehensionTestRunner(_orchestrator).runAdaptiveTest();
                    return r.generateReport();
                  }),
                ],
              ),
            ),
          ),

          // Input
          Container(
            color: const Color(0xFF0D1117),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type test message...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade600, fontFamily: 'monospace'),
                      filled: true,
                      fillColor: const Color(0xFF21262D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendTestMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _running ? null : _sendTestMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _running
                          ? Colors.grey.shade700
                          : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _running ? Icons.hourglass_top : Icons.send_rounded,
                      color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _metric('Emotion', _lastEmotion),
        _metric('Modality', _lastModality),
        _metric('Comp', '${(_lastComprehension * 100).toInt()}%'),
        _metric('Visual', _lastVisual),
        _metric('Latency', '${_latencyMs}ms'),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        children: [
          TextSpan(text: '$label:', style: TextStyle(color: Colors.grey.shade500)),
          TextSpan(text: value, style: const TextStyle(color: Colors.cyanAccent)),
        ],
      ),
    );
  }

  Widget _testBtn(String label, Future<String> Function() test) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ElevatedButton(
        onPressed: _running ? null : () => _runTest(label, test),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF21262D),
          foregroundColor: Colors.cyanAccent,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  void dispose() {
    _orchestrator.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
