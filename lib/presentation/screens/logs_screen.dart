import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logging/app_logger.dart';
import '../theme/app_theme.dart';
import '../theme/constants.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final AppLogger _log = AppLogger();
  List<String> _logLines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final content = await _log.readLogFile();
    if (mounted) {
      setState(() {
        _logLines = content.isEmpty ? [] : content.split('\n');
        _isLoading = false;
      });
    }
  }

  Future<void> _shareLogs() async {
    await _log.flush();
    final content = await _log.readLogFile();
    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Логи пустые')),
        );
      }
      return;
    }
    await Share.share(content, subject: 'KaraChords Logs');
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить логи?'),
        content: const Text('Все записанные логи будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _log.clearLog();
      if (mounted) {
        setState(() => _logLines = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Логи очищены')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Логи отладки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться',
            onPressed: _shareLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Очистить',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logLines.isEmpty
                    ? const Center(
                        child: Text(
                          'Логи пустые',
                          style: TextStyle(color: AppTheme.onSurface),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(kSpaceMd),
                        itemCount: _logLines.length,
                        itemBuilder: (context, index) {
                          final line = _logLines[index];
                          if (line.isEmpty) return const SizedBox.shrink();
                          return SelectableText(
                            line,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Roboto Mono',
                              color: AppTheme.onSurface,
                            ),
                          );
                        },
                      ),
          ),
          Container(
            width: double.infinity,
            color: AppTheme.surface,
            padding: const EdgeInsets.all(kSpaceMd),
            child: SelectableText(
              'Файл: ${_log.logFilePath}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textDisabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
