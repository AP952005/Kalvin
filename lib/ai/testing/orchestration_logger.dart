/// Kalvin AI — Orchestration Logger
///
/// Centralized logging for all AI subsystems. Tracks timestamps,
/// stages, latency, failures, and recovery attempts.

class OrchestrationLogger {
  static final OrchestrationLogger _instance = OrchestrationLogger._();
  factory OrchestrationLogger() => _instance;
  OrchestrationLogger._();

  final List<LogEntry> _logs = [];
  final Map<String, List<double>> _latencyMap = {};

  void info(String stage, String message) =>
      _add(LogLevel.info, stage, message);

  void warning(String stage, String message) =>
      _add(LogLevel.warning, stage, message);

  void error(String stage, String message) =>
      _add(LogLevel.error, stage, message);

  void performance(String stage, String message, {double? latencyMs}) {
    _add(LogLevel.performance, stage, message);
    if (latencyMs != null) {
      _latencyMap.putIfAbsent(stage, () => []);
      _latencyMap[stage]!.add(latencyMs);
    }
  }

  void _add(LogLevel level, String stage, String message) {
    _logs.add(LogEntry(
      level: level,
      stage: stage,
      message: message,
      timestamp: DateTime.now(),
    ));
    // Keep max 500 entries
    if (_logs.length > 500) _logs.removeAt(0);
  }

  List<LogEntry> get logs => List.unmodifiable(_logs);

  List<LogEntry> getByLevel(LogLevel level) =>
      _logs.where((e) => e.level == level).toList();

  List<LogEntry> getByStage(String stage) =>
      _logs.where((e) => e.stage == stage).toList();

  int get errorCount => getByLevel(LogLevel.error).length;
  int get warningCount => getByLevel(LogLevel.warning).length;

  double getAvgLatency(String stage) {
    final list = _latencyMap[stage];
    if (list == null || list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  Map<String, double> getAllAvgLatencies() {
    final result = <String, double>{};
    _latencyMap.forEach((stage, list) {
      result[stage] = list.reduce((a, b) => a + b) / list.length;
    });
    return result;
  }

  String exportReport() {
    final buf = StringBuffer();
    buf.writeln('=== KALVIN ORCHESTRATION LOG REPORT ===');
    buf.writeln('Total entries: ${_logs.length}');
    buf.writeln('Errors: $errorCount | Warnings: $warningCount');
    buf.writeln('\n--- Latency Summary ---');
    getAllAvgLatencies().forEach((stage, avg) {
      buf.writeln('  $stage: ${avg.toStringAsFixed(1)}ms avg');
    });
    buf.writeln('\n--- Recent Logs ---');
    for (final e in _logs.reversed.take(30)) {
      buf.writeln('[${e.level.name}] ${e.stage}: ${e.message}');
    }
    return buf.toString();
  }

  void clear() {
    _logs.clear();
    _latencyMap.clear();
  }
}

enum LogLevel { info, warning, error, performance }

class LogEntry {
  final LogLevel level;
  final String stage;
  final String message;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.stage,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] [${level.name}] $stage: $message';
}
