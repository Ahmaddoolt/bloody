// file: lib/core/utils/app_logger.dart
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

class AppLogger {
  // 🎨 ANSI Color Codes for Console
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';
  static const String _magenta = '\x1B[35m'; // Used for Data
  static const String _white = '\x1B[37m';

  /// Logs a generic info message (Blue)
  static void info(String message) {
    developer.log('$_cyanℹ️ [INFO] $message$_reset', name: 'BloodyApp');
  }

  /// Logs a success message (Green)
  static void success(String message) {
    developer.log('$_green✅ [SUCCESS] $message$_reset', name: 'BloodyApp');
  }

  /// Logs a warning (Yellow)
  static void warning(String message) {
    developer.log('$_yellow⚠️ [WARNING] $message$_reset', name: 'BloodyApp');
  }

  /// 📦 Logs Database Data in Pretty JSON Format (Purple)
  static void logData(String label, dynamic data) {
    try {
      final JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(data);
      developer.log(
        '$_magenta📦 [DATA: $label]\n$prettyJson$_reset',
        name: 'BloodyApp',
      );
    } catch (e) {
      developer.log(
        '$_magenta📦 [DATA: $label] (Could not parse JSON)\n$data$_reset',
        name: 'BloodyApp',
      );
    }
  }

  /// 🚨 Specifically handles Supabase Errors with Red details
  static void error(String context, dynamic error, [StackTrace? stackTrace]) {
    final buffer = StringBuffer();
    buffer.writeln('$_red❌ [ERROR] @ $context$_reset');

    if (error is PostgrestException) {
      // Database Errors
      buffer.writeln('$_red   ├─ 🗄️ Code: ${error.code}$_reset');
      buffer.writeln('$_red   ├─ 💬 Message: ${error.message}$_reset');
      if (error.details != null) {
        buffer.writeln('$_red   ├─ 📝 Details: ${error.details}$_reset');
      }
      buffer.writeln('$_red   └─ 💡 Hint: ${error.hint ?? "No hint"}$_reset');
    } else if (error is AuthException) {
      // Auth Errors
      buffer.writeln('$_red   ├─ 🔐 Auth Error: ${error.message}$_reset');
      buffer.writeln('$_red   └─ 🆔 StatusCode: ${error.statusCode}$_reset');
    } else {
      // Generic Dart Errors
      buffer.writeln('$_red   └─ 🐛 Exception: $error$_reset');
    }

    if (stackTrace != null) {
      buffer.writeln('$_white$stackTrace$_reset');
    }

    developer.log(buffer.toString(), name: 'BloodyApp', error: error);
  }
}
