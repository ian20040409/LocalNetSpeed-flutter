import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/gigabit_evaluation.dart';
import '../models/speed_test_mode.dart';
import '../models/speed_test_result.dart';
import '../services/gigabit_evaluator.dart';
import '../services/local_ip_helper.dart';
import '../services/speed_tester.dart';

enum SpeedUnit {
  mbps("Mbps"),
  gbps("Gbps"),
  mbs("MB/s"),
  kbps("Kbps");

  final String label;
  const SpeedUnit(this.label);

  double convertFromMBps(double mbps) {
    switch (this) {
      case SpeedUnit.mbps: return mbps * 8;
      case SpeedUnit.gbps: return mbps * 8 / 1024;
      case SpeedUnit.mbs: return mbps;
      case SpeedUnit.kbps: return mbps * 8 * 1024;
    }
  }
}

class ContentViewModel extends ChangeNotifier {
  AppLocalizations? _l10n;

  void setL10n(AppLocalizations l10n) {
    _l10n = l10n;
    if (_localIP.isEmpty) _localIP = l10n.fetchingIp;
    if (_progressText.isEmpty) _progressText = l10n.statusNotStarted;
    notifyListeners();
  }

  SpeedTestMode _mode = SpeedTestMode.server;
  SpeedTestMode get mode => _mode;
  set mode(SpeedTestMode v) {
    _mode = v;
    notifyListeners();
  }

  String _localIP = "";
  String get localIP => _localIP;

  ConnectionType _detectedConnectionType = ConnectionType.unknown;
  ConnectionType get detectedConnectionType => _detectedConnectionType;

  bool _autoEvaluationMode = true;
  bool get autoEvaluationMode => _autoEvaluationMode;
  set autoEvaluationMode(bool v) {
    _autoEvaluationMode = v;
    if (v) {
      _applyAutoEvaluationMode();
    }
    notifyListeners();
  }

  Future<void> fetchLocalIP() async {
    _localIP = _l10n?.fetchingIp ?? "";
    notifyListeners();
    final result = await LocalIPHelper.detectNetwork();
    _localIP = result.ip.isEmpty ? (_l10n?.ipUnavailable ?? "") : result.ip;
    _detectedConnectionType = result.connectionType;
    if (_autoEvaluationMode) {
      _applyAutoEvaluationMode();
    }
    notifyListeners();
  }

  void _applyAutoEvaluationMode() {
    switch (_detectedConnectionType) {
      case ConnectionType.wifi:
        _evaluationMode = EvaluationMode.wifi;
      case ConnectionType.wired:
        _evaluationMode = EvaluationMode.gigabit;
      case ConnectionType.unknown:
        _evaluationMode = EvaluationMode.gigabit;
    }
  }

  SpeedUnit _selectedUnit = SpeedUnit.mbps;
  SpeedUnit get selectedUnit => _selectedUnit;
  set selectedUnit(SpeedUnit v) {
    _selectedUnit = v;
    notifyListeners();
  }

  String _host = "";
  String get host => _host;
  set host(String v) {
    _host = v;
    notifyListeners();
  }

  String _port = "65432";
  String get port => _port;
  set port(String v) {
    _port = v;
    notifyListeners();
  }

  String _sizeMB = "100";
  String get sizeMB => _sizeMB;
  set sizeMB(String v) {
    _sizeMB = v;
    notifyListeners();
  }

  // Time-bounded mode
  bool _useTimeBounded = false;
  bool get useTimeBounded => _useTimeBounded;
  set useTimeBounded(bool v) {
    _useTimeBounded = v;
    notifyListeners();
  }

  String _durationSeconds = "10";
  String get durationSeconds => _durationSeconds;
  set durationSeconds(String v) {
    _durationSeconds = v;
    notifyListeners();
  }

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  String _progressText = "";
  String get progressText => _progressText;

  String _log = "";
  String get log => _log;

  SpeedTestResult? _result;
  SpeedTestResult? get result => _result;

  int _serverConnectionCount = 0;
  int get serverConnectionCount => _serverConnectionCount;

  EvaluationMode _evaluationMode = EvaluationMode.gigabit;
  EvaluationMode get evaluationMode => _evaluationMode;
  set evaluationMode(EvaluationMode v) {
    _evaluationMode = v;
    _autoEvaluationMode = false; // Manual override disables auto
    notifyListeners();
  }

  bool _enableRetry = true;
  bool get enableRetry => _enableRetry;
  set enableRetry(bool v) {
    _enableRetry = v;
    notifyListeners();
  }

  SpeedTester? _tester;

  void start() {
    if (_isRunning) return;
    _result = null;
    _log = "";
    _progressText = _l10n?.statusPreparing ?? "Preparing...";
    notifyListeners();

    int? p = int.tryParse(_port);
    if (p == null) {
      _progressText = _l10n?.statusErrorPort ?? "Invalid port number";
      notifyListeners();
      return;
    }

    _tester = SpeedTester();
    _isRunning = true;
    notifyListeners();

    if (_mode == SpeedTestMode.server) {
      _serverConnectionCount = 0;
      _appendLog(_l10n?.logServerStarted(p) ?? "Server started, port $p, waiting for connection...");
      _tester!.runServer(
        port: p,
        l10n: _l10n!,
        evaluationMode: _evaluationMode,
        progress: (bytes) {
          double mb = bytes / 1024 / 1024;
          _progressText = _l10n?.statusReceived(mb.toStringAsFixed(1)) ?? "Received ${mb.toStringAsFixed(1)} MB";
          notifyListeners();
        },
        completion: (res) {
          _handleCompletion(res);
        },
        onNewConnection: (count) {
          _serverConnectionCount = count;
          _appendLog(_l10n?.logNewConnection(count) ?? "New connection #$count");
          notifyListeners();
        },
      );
    } else {
      if (_host.trim().isEmpty) {
        _progressText = _l10n?.statusErrorNoHost ?? "Please enter server IP";
        _isRunning = false;
        notifyListeners();
        return;
      }

      if (_useTimeBounded) {
        // Time-bounded mode
        int? dur = int.tryParse(_durationSeconds);
        if (dur == null || dur <= 0) {
          _progressText = _l10n?.statusErrorDuration ?? "Invalid test duration";
          _isRunning = false;
          notifyListeners();
          return;
        }

        _appendLog(_l10n?.logClientConnectingTimeBounded(_host, p, dur)
            ?? "Client connecting to $_host:$p, time-bounded test ${dur}s (4 parallel streams)...");
        _tester!.runClient(
          host: _host,
          port: p,
          l10n: _l10n!,
          totalSizeMB: 10000,
          durationSeconds: dur,
          concurrency: 4,
          progress: (sent) {
            double mb = sent / 1024 / 1024;
            _progressText = _l10n?.statusSent(mb.toStringAsFixed(1)) ?? "Sent ${mb.toStringAsFixed(1)} MB";
            notifyListeners();
          },
          completion: (res) {
            _handleCompletion(res);
          },
          retryStatus: (attempt, maxAttempts) {
            if (attempt == 1) {
              _progressText = _l10n?.statusConnecting ?? "Connecting...";
            } else if (attempt <= 5) {
              _progressText = _l10n?.statusRetrying(attempt, maxAttempts)
                  ?? "Retrying connection ($attempt/$maxAttempts)...";
              _appendLog(_l10n?.logRetryAttempt(attempt) ?? "Connection attempt #$attempt...");
            } else {
              _progressText = _l10n?.statusWaitingServer(attempt, maxAttempts)
                  ?? "Waiting for server to start... ($attempt/$maxAttempts)";
              if (attempt % 5 == 0) {
                _appendLog(_l10n?.logWaitingServer(attempt)
                    ?? "Still waiting for server to start... (attempt $attempt)");
              }
            }
            notifyListeners();
          },
          enableRetry: _enableRetry,
          evaluationMode: _evaluationMode,
        );
      } else {
        // Size-bounded mode
        int? size = int.tryParse(_sizeMB);
        if (size == null || size <= 0) {
          _progressText = _l10n?.statusErrorSize ?? "Invalid data size";
          _isRunning = false;
          notifyListeners();
          return;
        }

        _appendLog(_l10n?.logClientConnectingSizeBounded(_host, p, size)
            ?? "Client connecting to $_host:$p, sending $size MB (4 parallel streams)...");
        _tester!.runClient(
          host: _host,
          port: p,
          l10n: _l10n!,
          totalSizeMB: size,
          concurrency: 4,
          progress: (sent) {
            double percent = sent / (size * 1024 * 1024) * 100;
            _progressText = _l10n?.statusProgress(percent.toStringAsFixed(1))
                ?? "Progress ${percent.toStringAsFixed(1)}%";
            notifyListeners();
          },
          completion: (res) {
            _handleCompletion(res);
          },
          retryStatus: (attempt, maxAttempts) {
            if (attempt == 1) {
              _progressText = _l10n?.statusConnecting ?? "Connecting...";
            } else if (attempt <= 5) {
              _progressText = _l10n?.statusRetrying(attempt, maxAttempts)
                  ?? "Retrying connection ($attempt/$maxAttempts)...";
              _appendLog(_l10n?.logRetryAttempt(attempt) ?? "Connection attempt #$attempt...");
            } else {
              _progressText = _l10n?.statusWaitingServer(attempt, maxAttempts)
                  ?? "Waiting for server to start... ($attempt/$maxAttempts)";
              if (attempt % 5 == 0) {
                _appendLog(_l10n?.logWaitingServer(attempt)
                    ?? "Still waiting for server to start... (attempt $attempt)");
              }
            }
            notifyListeners();
          },
          enableRetry: _enableRetry,
          evaluationMode: _evaluationMode,
        );
      }
    }
  }

  void cancel() {
    _tester?.cancel();
    _isRunning = false;
    _progressText = _l10n?.statusCancelled ?? "Cancelled";
    _appendLog(_l10n?.logCancelled ?? "Test cancelled");
    if (_mode == SpeedTestMode.server) {
      _serverConnectionCount = 0;
    }
    notifyListeners();
  }

  void forceStopServer() {
    _tester?.cancel();
    _tester = null;
    _isRunning = false;
    _serverConnectionCount = 0;
    _progressText = _l10n?.statusForceStopped ?? "Server force stopped";
    _appendLog(_l10n?.logForceStopped ?? "Server force stopped");
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void _handleCompletion(Result<SpeedTestResult> res) {
    if (res.isSuccess) {
      _result = res.value;
      HapticFeedback.mediumImpact();

      if (_mode == SpeedTestMode.server) {
        _progressText = _l10n?.statusWaitingConnection ?? "Waiting for connection...";
        _appendLog(_formatResult(_result!));
        _appendLog(_l10n?.logServerContinues ?? "--- Server continuing, waiting for next connection ---");
      } else {
        _isRunning = false;
        _progressText = _l10n?.statusDone ?? "Done";
        _appendLog(_formatResult(_result!));
      }
    } else {
      HapticFeedback.vibrate();
      final errMsg = res.error.toString();
      if (_mode == SpeedTestMode.server) {
        _progressText = _l10n?.statusWaitingConnection ?? "Waiting for connection...";
        _appendLog(_l10n?.logError(errMsg) ?? "Error: $errMsg");
        _appendLog(_l10n?.logServerContinues ?? "--- Server continuing, waiting for next connection ---");
      } else {
        _isRunning = false;
        _progressText = _l10n?.statusError(errMsg) ?? "Error: $errMsg";
        _appendLog(_l10n?.logError(errMsg) ?? "Error: $errMsg");
      }
    }
    notifyListeners();
  }

  void clearLog() {
    _log = "";
    notifyListeners();
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  void _appendLog(String line) {
    if (_log.isEmpty) {
      _log = line;
    } else {
      _log = "$_log\n$line";
    }
    notifyListeners();
  }

  String _localizedModeLabel(EvaluationMode m) {
    if (_l10n == null) return m.label;
    switch (m) {
      case EvaluationMode.gigabit:
        return _l10n!.evaluationModeGigabit;
      case EvaluationMode.wifi:
        return _l10n!.evaluationModeWifi;
    }
  }

  String _formatResult(SpeedTestResult r) {
    final eval = r.evaluation;
    final totalMB = (r.transferredBytes / 1024 / 1024).toStringAsFixed(2);
    final durationStr = r.duration.toStringAsFixed(2);

    final val = _selectedUnit.convertFromMBps(r.speedMBps);
    final speedStr = val.toStringAsFixed(2);
    final unitStr = _selectedUnit.label;

    final evalSpeedVal = _selectedUnit.convertFromMBps(eval.speedMBps);
    final evalSpeed = evalSpeedVal.toStringAsFixed(2);

    final theoreticalVal = _selectedUnit.convertFromMBps(GigabitEvaluator.theoreticalForMode(eval.mode));
    final theoreticalStr = theoreticalVal.toStringAsFixed(0);

    final percentStr = eval.performancePercent.toStringAsFixed(1);
    final modeLabel = _localizedModeLabel(eval.mode);

    final l = _l10n;
    final buffer = StringBuffer();
    buffer.writeln(l?.logResultHeader ?? "--- Test Result ---");
    buffer.writeln(l?.logResultTotal(totalMB) ?? "Total: $totalMB MB");
    buffer.writeln(l?.logResultDuration(durationStr) ?? "Duration: $durationStr sec");
    buffer.writeln(l?.logResultSpeed(speedStr, unitStr) ?? "Speed: $speedStr $unitStr");
    if (r.p50SpeedMBps != null) {
      final p50Val = _selectedUnit.convertFromMBps(r.p50SpeedMBps!);
      buffer.writeln(l?.logResultP50(p50Val.toStringAsFixed(2), unitStr)
          ?? "P50 (median sustained): ${p50Val.toStringAsFixed(2)} $unitStr");
    }
    if (r.p90SpeedMBps != null) {
      final p90Val = _selectedUnit.convertFromMBps(r.p90SpeedMBps!);
      buffer.writeln(l?.logResultP90(p90Val.toStringAsFixed(2), unitStr)
          ?? "P90 (peak sustained): ${p90Val.toStringAsFixed(2)} $unitStr");
    }
    buffer.writeln("");
    buffer.writeln(l?.logResultEvalHeader(modeLabel) ?? "--- $modeLabel Evaluation ---");
    buffer.writeln(l?.logResultActualSpeed(evalSpeed, unitStr) ?? "Actual speed: $evalSpeed $unitStr");
    buffer.writeln(l?.logResultTheoretical(theoreticalStr, unitStr) ?? "Theoretical: $theoreticalStr $unitStr");
    buffer.writeln(l?.logResultPercent(percentStr) ?? "Achievement: $percentStr%");
    buffer.writeln(l?.logResultRating(eval.icon, eval.rating) ?? "Rating: ${eval.icon} ${eval.rating}");
    buffer.writeln(l?.logResultSuggestion(eval.message) ?? "Suggestion: ${eval.message}");
    if (eval.suggestions.isNotEmpty) {
      buffer.writeln(l?.logResultImprovements ?? "Improvement tips:");
      for (var s in eval.suggestions) {
        buffer.writeln("• $s");
      }
    }
    return buffer.toString();
  }
}
