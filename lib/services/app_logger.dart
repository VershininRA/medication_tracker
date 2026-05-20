import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'MediCycle';

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$_tag] DEBUG: $message');
      if (error != null) {
        debugPrint('Error: $error');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
      }
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] INFO: $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] ⚠️ WARNING: $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[$_tag] ❌ ERROR: $message');
    if (error != null) {
      debugPrint('Error Details: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('[$_tag] ✓ SUCCESS: $message');
    }
  }

  // Для отслеживания жизненного цикла
  static void lifecycle(String screen, String event) {
    if (kDebugMode) {
      debugPrint('[$_tag] 📱 Lifecycle: $screen -> $event');
    }
  }
}
