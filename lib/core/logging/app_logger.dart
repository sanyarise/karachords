import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../version.dart';

/// Application-wide logger that writes to both console and a log file.
///
/// The log file is stored in the app's documents directory and can be
/// shared for debugging purposes.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late Logger _logger;
  late File _logFile;
  final List<String> _memoryBuffer = [];
  bool _initialized = false;
  _FileOutput? _fileOutput;

  Logger get logger => _logger;

  Future<void> init() async {
    if (_initialized) return;

    Directory? logDir;
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        logDir = Directory('${extDir.path}/logs');
      }
    } catch (_) {
      // Fallback below.
    }

    if (logDir == null) {
      final docDir = await getApplicationDocumentsDirectory();
      logDir = Directory('${docDir.path}/logs');
    }

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    _logFile = File('${logDir.path}/karachords.log');

    _fileOutput = _FileOutput(_logFile, _memoryBuffer);

    _logger = Logger(
      filter: ProductionFilter(),
      printer: SimplePrinter(printTime: true),
      output: MultiOutput([
        ConsoleOutput(),
        _fileOutput!,
      ]),
    );

    _initialized = true;
    i('Logger initialized. Version: $kAppVersion. Log file: ${_logFile.path}');
  }

  void d(String message) => _logger.d(message);
  void i(String message) => _logger.i(message);
  void w(String message) => _logger.w(message);
  void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Returns the path to the log file.
  String get logFilePath => _logFile.path;

  /// Returns the contents of the log file.
  Future<String> readLogFile() async {
    if (!await _logFile.exists()) return '';
    return _logFile.readAsString();
  }

  /// Clears the log file.
  Future<void> clearLog() async {
    if (await _logFile.exists()) {
      await _logFile.writeAsString('');
    }
    _memoryBuffer.clear();
  }

  /// Returns recent log entries from memory buffer.
  List<String> getRecentLogs({int count = 100}) {
    if (_memoryBuffer.length <= count) return List.from(_memoryBuffer);
    return _memoryBuffer.sublist(_memoryBuffer.length - count);
  }

  /// Forces any pending log lines to be written to disk immediately.
  Future<void> flush() async {
    await _fileOutput?.flush();
  }
}

/// Custom file output for logger that also keeps a memory buffer.
///
/// Writes are batched and flushed asynchronously so they never block
/// the UI thread.
class _FileOutput extends LogOutput {
  final File file;
  final List<String> memoryBuffer;
  final int _maxBufferSize = 500;
  static const int _maxLogSize = 1024 * 1024; // 1 MB
  static const int _maxLogFiles = 5;

  final List<String> _pendingLines = [];
  bool _flushScheduled = false;

  _FileOutput(this.file, this.memoryBuffer);

  @override
  void output(OutputEvent event) {
    final lines = event.lines;
    for (final line in lines) {
      memoryBuffer.add(line);
      if (memoryBuffer.length > _maxBufferSize) {
        memoryBuffer.removeAt(0);
      }
      _writeToFile(line);
    }
  }

  void _writeToFile(String line) {
    _pendingLines.add(line);
    if (!_flushScheduled) {
      _flushScheduled = true;
      Future.delayed(Duration.zero, _flush);
    }
  }

  Future<void> flush() async => _flush();

  Future<void> _flush() async {
    _flushScheduled = false;
    if (_pendingLines.isEmpty) return;

    await _rotateIfNeeded();

    final lines = _pendingLines.toList();
    _pendingLines.clear();

    try {
      await file.writeAsString(
        lines.map((l) => '$l\n').join(),
        mode: FileMode.append,
      );
    } catch (_) {
      // Ignore file write errors to prevent crash loops.
    }
  }

  Future<void> _rotateIfNeeded() async {
    if (!await file.exists()) return;
    final size = await file.length();
    if (size < _maxLogSize) return;

    // Rotate backups: .4 -> .5, .3 -> .4, ..., .1 -> .2
    for (int i = _maxLogFiles - 1; i > 0; i--) {
      final older = File('${file.path}.$i');
      final newer = File('${file.path}.${i + 1}');
      if (await older.exists()) {
        await older.rename(newer.path);
      }
    }
    final firstBackup = File('${file.path}.1');
    await file.rename(firstBackup.path);
  }
}
