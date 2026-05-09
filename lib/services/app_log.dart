import 'dart:collection';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogEntry {
  final DateTime time;
  final bool isError;
  final String message;

  const AppLogEntry({
    required this.time,
    required this.isError,
    required this.message,
  });

  String get timeStr {
    final t = time;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => '$timeStr [${isError ? 'ERROR' : 'INFO '}] $message';
}

class AppLog {
  AppLog._();
  static final AppLog _instance = AppLog._();

  static const _maxEntries = 200;
  final _buffer = Queue<AppLogEntry>();

  static void info(String message) => _instance._add(false, message);

  static void error(String message, [Object? err]) =>
      _instance._add(true, err != null ? '$message: $err' : message);

  static List<AppLogEntry> get entries => List.unmodifiable(_instance._buffer);

  static String formatted() =>
      _instance._buffer.map((e) => e.toString()).join('\n');

  void _add(bool isError, String message) {
    final entry = AppLogEntry(
      time: DateTime.now(),
      isError: isError,
      message: message,
    );
    dev.log(message, name: 'TennisLogger', level: isError ? 1000 : 800);
    debugPrint('TennisLogger: $message');
    _buffer.addLast(entry);
    if (_buffer.length > _maxEntries) _buffer.removeFirst();
  }
}
