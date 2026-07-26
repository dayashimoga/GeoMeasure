import 'package:flutter/foundation.dart';

/// Structured logging service with severity levels and context.
///
/// In production, this would pipe to Crashlytics, Sentry, or
/// a structured logging backend. Currently outputs to debugPrint
/// for development visibility.
enum LogLevel { debug, info, warning, error, fatal }

class AppLogger {
  static final AppLogger _instance = AppLogger._();
  factory AppLogger() => _instance;
  AppLogger._();

  LogLevel _minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  final List<LogEntry> _buffer = [];
  static const int _maxBufferSize = 500;

  void setMinimumLevel(LogLevel level) => _minimumLevel = level;

  void debug(String message, {String? tag, Map<String, dynamic>? context}) =>
      _log(LogLevel.debug, message, tag: tag, context: context);

  void info(String message, {String? tag, Map<String, dynamic>? context}) =>
      _log(LogLevel.info, message, tag: tag, context: context);

  void warning(String message, {String? tag, Map<String, dynamic>? context}) =>
      _log(LogLevel.warning, message, tag: tag, context: context);

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) =>
      _log(
        LogLevel.error,
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
        context: context,
      );

  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(
        LogLevel.fatal,
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (level.index < _minimumLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag ?? 'GeoMeasure',
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    _buffer.add(entry);
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    final prefix = '[${level.name.toUpperCase()}][${entry.tag}]';
    debugPrint('$prefix $message');
    if (error != null) debugPrint('  Error: $error');
    if (stackTrace != null) debugPrint('  $stackTrace');
  }

  List<LogEntry> getRecentLogs({int count = 50}) {
    final start = _buffer.length > count ? _buffer.length - count : 0;
    return _buffer.sublist(start);
  }

  void clear() => _buffer.clear();
}

class LogEntry {
  final LogLevel level;
  final String message;
  final String tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const LogEntry({
    required this.level,
    required this.message,
    required this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'message': message,
        'tag': tag,
        'timestamp': timestamp.toIso8601String(),
        if (error != null) 'error': error.toString(),
        if (context != null) 'context': context,
      };
}

/// Convenience global accessor
final logger = AppLogger();
