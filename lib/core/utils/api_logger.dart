import 'dart:convert';
import 'package:flutter/foundation.dart';

/// ANSI color codes for terminal output
class _Colors {
  static const String reset = '\x1B[0m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String red = '\x1B[31m';
  static const String cyan = '\x1B[36m';
  static const String dim = '\x1B[2m';
  static const String bgGreen = '\x1B[42m\x1B[37m\x1B[1m';
  static const String bgBlue = '\x1B[44m\x1B[37m\x1B[1m';
  static const String bgYellow = '\x1B[43m\x1B[37m\x1B[1m';
  static const String bgRed = '\x1B[41m\x1B[37m\x1B[1m';
  static const String white = '\x1B[37m';
}

abstract class ApiLogger {
  static void logResponse({
    required String method,
    required String endpoint,
    required int statusCode,
    required dynamic data,
    int? durationMs,
  }) {
    if (!kDebugMode) return;

    final methodColor = _getMethodColor(method);
    final statusColor = statusCode >= 200 && statusCode < 300
        ? _Colors.green
        : (statusCode >= 400 ? _Colors.red : _Colors.yellow);
    final emoji = statusCode >= 200 && statusCode < 300
        ? '✅'
        : (statusCode >= 400 ? '❌' : '⚠️');
    final durationStr = durationMs != null
        ? '${_Colors.dim} (${durationMs}ms)${_Colors.reset}'
        : '';
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);

    // Use print instead of debugPrint for better color support in IDE consoles
    _log('');
    _log(
        '${_Colors.dim}${_Colors.cyan}╔═══════════════════════════════════════════════════════════════${_Colors.reset}');
    _log(
        '${_Colors.cyan}║${_Colors.reset}  $methodColor $method ${_Colors.reset} $endpoint');
    _log(
        '${_Colors.cyan}║${_Colors.reset}  $statusColor$emoji $statusCode${_Colors.reset}$durationStr  ${_Colors.dim}$timestamp${_Colors.reset}');
    _log(
        '${_Colors.cyan}╠═══════════════════════════════════════════════════════════════${_Colors.reset}');

    try {
      final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
      final lines = prettyJson.split('\n').take(30);
      for (final line in lines) {
        // Use green for JSON values in success responses, red for errors
        final contentColor =
            statusCode >= 200 && statusCode < 300 ? _Colors.green : _Colors.red;
        _log(
            '${_Colors.cyan}║${_Colors.reset}  $contentColor$line${_Colors.reset}');
      }
    } catch (_) {
      final str = data.toString();
      final contentColor =
          statusCode >= 200 && statusCode < 300 ? _Colors.green : _Colors.red;
      if (str.length > 500) {
        _log(
            '${_Colors.cyan}║${_Colors.reset}  $contentColor${str.substring(0, 500)}...${_Colors.reset}');
      } else {
        _log(
            '${_Colors.cyan}║${_Colors.reset}  $contentColor$str${_Colors.reset}');
      }
    }

    _log(
        '${_Colors.dim}${_Colors.cyan}╚═══════════════════════════════════════════════════════════════${_Colors.reset}');
    _log('');
  }

  static void logError({
    required String method,
    required String endpoint,
    required Object error,
    int? statusCode,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);

    _log('');
    _log(
        '${_Colors.red}╔═══════════════════════════════════════════════════════════════${_Colors.reset}');
    _log(
        '${_Colors.red}║${_Colors.reset}  ${_Colors.bgRed} $method ${_Colors.reset}  $endpoint');
    if (statusCode != null) {
      _log(
          '${_Colors.red}║${_Colors.reset}  ${_Colors.red}❌ ERROR $statusCode${_Colors.reset} — ${_Colors.dim}$timestamp${_Colors.reset}');
    } else {
      _log(
          '${_Colors.red}║${_Colors.reset}  ${_Colors.red}❌ NETWORK ERROR${_Colors.reset} — ${_Colors.dim}$timestamp${_Colors.reset}');
    }
    _log(
        '${_Colors.red}╠═══════════════════════════════════════════════════════════════${_Colors.reset}');
    _log(
        '${_Colors.red}║${_Colors.reset}  ${_Colors.red}${error.runtimeType}${_Colors.reset}');
    _log(
        '${_Colors.red}║${_Colors.reset}  ${_Colors.red}$error${_Colors.reset}');
    _log(
        '${_Colors.red}╚═══════════════════════════════════════════════════════════════${_Colors.reset}');
    _log('');
  }

  static void _log(String message) {
    // Using print instead of debugPrint for better color support
    // ignore: avoid_print
    print(message);
  }

  static String _getMethodColor(String method) {
    return switch (method.toUpperCase()) {
      'GET' => _Colors.bgGreen,
      'POST' => _Colors.bgBlue,
      'PUT' => _Colors.bgYellow,
      'DELETE' => _Colors.bgRed,
      _ => _Colors.bgBlue,
    };
  }
}
