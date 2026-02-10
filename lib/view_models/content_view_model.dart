import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  SpeedTestMode _mode = SpeedTestMode.server;
  SpeedTestMode get mode => _mode;
  set mode(SpeedTestMode v) {
    _mode = v;
    notifyListeners();
  }

  String _localIP = "獲取中...";
  String get localIP => _localIP;
  
  Future<void> fetchLocalIP() async {
    _localIP = "獲取中...";
    notifyListeners();
    _localIP = await LocalIPHelper.getLocalIPAddress();
    notifyListeners();
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

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  String _progressText = "尚未開始";
  String get progressText => _progressText;

  String _log = "";
  String get log => _log;

  SpeedTestResult? _result;
  SpeedTestResult? get result => _result;

  int _serverConnectionCount = 0;
  int get serverConnectionCount => _serverConnectionCount;

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
    _progressText = "準備中...";
    notifyListeners();

    int? p = int.tryParse(_port);
    if (p == null) {
      _progressText = "埠號不正確";
      notifyListeners();
      return;
    }

    _tester = SpeedTester();
    _isRunning = true;
    notifyListeners();

    if (_mode == SpeedTestMode.server) {
      _serverConnectionCount = 0;
      _appendLog("伺服器啟動，埠 $p，等待連線...");
      _tester!.runServer(
        port: p,
        progress: (bytes) {
          double mb = bytes / 1024 / 1024;
          _progressText = "已接收 ${mb.toStringAsFixed(1)} MB";
          notifyListeners();
        },
        completion: (res) {
          _handleCompletion(res);
        },
        onNewConnection: (count) {
          _serverConnectionCount = count;
          _appendLog("新連線 #$count");
          notifyListeners();
        },
      );
    } else {
      if (_host.trim().isEmpty) {
        _progressText = "請輸入伺服器 IP";
        _isRunning = false;
        notifyListeners();
        return;
      }
      int? size = int.tryParse(_sizeMB);
      if (size == null || size <= 0) {
        _progressText = "資料大小不正確";
        _isRunning = false;
        notifyListeners();
        return;
      }

      _appendLog("客戶端連線到 $_host:$p，傳送 $size MB...");
      _tester!.runClient(
        host: _host,
        port: p,
        totalSizeMB: size,
        progress: (sent) {
          double percent = sent / (size * 1024 * 1024) * 100;
          _progressText = "進度 ${percent.toStringAsFixed(1)}%";
          notifyListeners();
        },
        completion: (res) {
          _handleCompletion(res);
        },
        retryStatus: (attempt, maxAttempts) {
          if (attempt == 1) {
            _progressText = "正在連線...";
          } else if (attempt <= 5) {
            _progressText = "重試連線 ($attempt/$maxAttempts)...";
            _appendLog("第 $attempt 次連線嘗試...");
          } else {
            _progressText = "等待伺服器啟動... ($attempt/$maxAttempts)";
            if (attempt % 5 == 0) {
              _appendLog("持續等待伺服器啟動... (第 $attempt 次嘗試)");
            }
          }
          notifyListeners();
        },
        enableRetry: _enableRetry,
      );
    }
  }

  void cancel() {
    _tester?.cancel();
    _isRunning = false;
    _progressText = "已取消";
    _appendLog("測試已取消");
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
    _progressText = "伺服器已強制停止";
    _appendLog("伺服器已強制停止");
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void _handleCompletion(Result<SpeedTestResult> res) {
    if (res.isSuccess) {
      _result = res.value;
      HapticFeedback.mediumImpact(); // Flutter doesn't have explicit 'success' haptic in standard, medium is close
      
      if (_mode == SpeedTestMode.server) {
        _progressText = "等待連線...";
        _appendLog(_formatResult(_result!));
        _appendLog("--- 伺服器繼續運行，等待下一個連線 ---");
      } else {
        _isRunning = false;
        _progressText = "完成";
        _appendLog(_formatResult(_result!));
      }
    } else {
      HapticFeedback.vibrate(); // Error haptic
      if (_mode == SpeedTestMode.server) {
        _progressText = "等待連線...";
        _appendLog("錯誤：${res.error}");
        _appendLog("--- 伺服器繼續運行，等待下一個連線 ---");
      } else {
        _isRunning = false;
        _progressText = "錯誤：${res.error}";
        _appendLog("錯誤：${res.error}");
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

  String _formatResult(SpeedTestResult r) {
    final eval = r.evaluation;
    final totalMB = (r.transferredBytes / 1024 / 1024).toStringAsFixed(2);
    final durationStr = r.duration.toStringAsFixed(2);
    
    final val = _selectedUnit.convertFromMBps(r.speedMBps);
    final speedStr = val.toStringAsFixed(2);
    final unitStr = _selectedUnit.label;

    final evalSpeedVal = _selectedUnit.convertFromMBps(eval.speedMBps);
    final evalSpeed = evalSpeedVal.toStringAsFixed(2);

    final theoreticalVal = _selectedUnit.convertFromMBps(GigabitEvaluator.theoreticalMBps);
    final theoreticalStr = theoreticalVal.toStringAsFixed(0);

    final percentStr = eval.performancePercent.toStringAsFixed(1);

    final buffer = StringBuffer();
    buffer.writeln("--- 測試結果 ---");
    buffer.writeln("總量: $totalMB MB");
    buffer.writeln("耗時: $durationStr 秒");
    buffer.writeln("平均: $speedStr $unitStr");
    buffer.writeln("");
    buffer.writeln("--- Gigabit 評估 ---");
    buffer.writeln("實際速度: $evalSpeed $unitStr");
    buffer.writeln("理論: $theoreticalStr $unitStr");
    buffer.writeln("達成比例: $percentStr %");
    buffer.writeln("評級: ${eval.rating}");
    buffer.writeln("建議: ${eval.message}");
    if (eval.suggestions.isNotEmpty) {
      buffer.writeln("改善建議:");
      for (var s in eval.suggestions) {
        buffer.writeln("• $s");
      }
    }
    return buffer.toString();
  }
}
