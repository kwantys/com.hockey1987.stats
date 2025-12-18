import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service (п. 3.1 гайду)
class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: kDebugMode ? 2 : 0,
      errorMethodCount: kDebugMode ? 8 : 0,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: kDebugMode,
    ),
  );

  AppLogger._();

  static void d(String message) { if (kDebugMode) _logger.d(message); }
  static void i(String message) { if (kDebugMode) _logger.i(message); }
  static void w(String message) { if (kDebugMode) _logger.w(message); }

  // ВИПРАВЛЕНО: Використання іменованих аргументів для методу e
  static void e(String message, [dynamic error, StackTrace? stack]) {
    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stack);
    }
  }
}