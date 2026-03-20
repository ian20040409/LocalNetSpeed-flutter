import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/gigabit_evaluation.dart';
import '../models/speed_test_result.dart';
import 'gigabit_evaluator.dart';

class SpeedTester {
  static const int defaultPort = 65432;
  static const int defaultChunkSize = 1024 * 1024; // 1MB
  static const int maxRetryAttempts = 50;
  static const double retryDelaySeconds = 2.0;
  static const double retryDelayIncrement = 0.5;

  ServerSocket? _serverSocket;
  // Multi-stream support
  final List<Socket> _clientSockets = [];
  bool _isCancelled = false;

  // Server state for aggregation
  int _serverTotalReceivedBytes = 0;
  DateTime? _serverTestStartTime;
  int _activeConnections = 0; // Track active streams for session management

  // Sliding Window Algorithm state
  // Each checkpoint: (milliseconds from test start, cumulative bytes)
  final List<(int ms, int bytes)> _checkpoints = [];
  DateTime? _testStartTime; // Shared start time for both server and client

  // Retry state
  Timer? _retryTimer;
  Timer? _connectionTimeoutTimer;

  void cancel() {
    _isCancelled = true;
    _retryTimer?.cancel();
    _connectionTimeoutTimer?.cancel();

    if (!kIsWeb) {
      try {
        _serverSocket?.close();
        _serverSocket = null;
      } catch (_) {}

      for (var s in _clientSockets) {
        try { s.destroy(); } catch (_) {}
      }
      _clientSockets.clear();
    }

    _resetServerSession();
    _activeConnections = 0;
  }

  void _resetServerSession() {
    _serverTotalReceivedBytes = 0;
    _serverTestStartTime = null;
    _testStartTime = null;
    _checkpoints.clear();
  }

  // --- Server ---

  Future<void> runServer({
    required int port,
    required AppLocalizations l10n,
    required Function(int) progress,
    required Function(Result<SpeedTestResult>) completion,
    Function(int)? onNewConnection,
    EvaluationMode evaluationMode = EvaluationMode.gigabit,
  }) async {
    if (kIsWeb) {
      completion(Result.failure(Exception("Web platform does not support TCP Server Sockets.")));
      return;
    }

    _isCancelled = false;
    _activeConnections = 0;
    _resetServerSession();

    int totalConnectionCounter = 0;

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    } catch (e) {
      completion(Result.failure(e));
      return;
    }

    _serverSocket!.listen((Socket socket) {
      if (_isCancelled) {
        socket.destroy();
        return;
      }

      // Start of a new session (first stream)
      if (_activeConnections == 0) {
        _resetServerSession();
        _serverTestStartTime = DateTime.now();
        _testStartTime = _serverTestStartTime;
      }
      _activeConnections++;

      totalConnectionCounter++;
      if (onNewConnection != null) {
        onNewConnection(totalConnectionCounter);
      }

      socket.setOption(SocketOption.tcpNoDelay, true);

      DateTime lastProgressTime = DateTime.now();

      socket.listen(
        (List<int> data) {
          _serverTotalReceivedBytes += data.length;

          DateTime now = DateTime.now();
          if (now.difference(lastProgressTime).inMilliseconds > 100) {
            progress(_serverTotalReceivedBytes);
            _addCheckpoint(_serverTotalReceivedBytes, now);
            lastProgressTime = now;
          }
        },
        onError: (error) {
          _activeConnections--;
          socket.destroy();
        },
        onDone: () {
          _activeConnections--;
          socket.destroy();

          // End of session (last stream)
          if (_activeConnections == 0) {
            DateTime endTime = DateTime.now();
            DateTime start = _serverTestStartTime ?? endTime;
            double duration = endTime.difference(start).inMicroseconds / 1000000.0;

            final (double p50, double p90) = _calculateSlidingWindowSpeed();
            double speed = p50 > 0
                ? p50
                : (_serverTotalReceivedBytes / 1024 / 1024) / (duration > 0 ? duration : 0.0001);

            var eval = GigabitEvaluator.evaluate(speed, l10n, mode: evaluationMode);
            var result = SpeedTestResult(
              transferredBytes: _serverTotalReceivedBytes,
              duration: duration,
              startedAt: start,
              endedAt: endTime,
              evaluation: eval,
              p50SpeedMBps: p50 > 0 ? p50 : null,
              p90SpeedMBps: p90 > 0 ? p90 : null,
            );

            completion(Result.success(result));
          }
        },
        cancelOnError: true,
      );
    }, onError: (error) {
      if (!_isCancelled) {
        completion(Result.failure(error));
      }
    });
  }

  // --- Client ---

  Future<void> runClient({
    required String host,
    required int port,
    required AppLocalizations l10n,
    int totalSizeMB = 500,  // Large default for time-bounded mode
    int? durationSeconds,   // Non-null = time-bounded mode
    required Function(int) progress,
    required Function(Result<SpeedTestResult>) completion,
    Function(int, int)? retryStatus,
    bool enableRetry = true,
    int concurrency = 4,
    EvaluationMode evaluationMode = EvaluationMode.gigabit,
  }) async {
    if (kIsWeb) {
      completion(Result.failure(Exception("Web platform does not support TCP Client Sockets.")));
      return;
    }

    _isCancelled = false;
    _clientSockets.clear();
    _checkpoints.clear();

    // Divide total size among streams
    int sizePerStream = (totalSizeMB / concurrency).ceil();
    if (sizePerStream < 1) sizePerStream = 1;

    List<Future<void>> futures = [];
    // Shared progress tracking
    List<int> streamProgress = List.filled(concurrency, 0);
    DateTime startTime = DateTime.now();
    _testStartTime = startTime;

    // Compute deadline for time-bounded mode
    DateTime? deadline = durationSeconds != null
        ? startTime.add(Duration(seconds: durationSeconds))
        : null;

    for (int i = 0; i < concurrency; i++) {
      int streamIndex = i;
      futures.add(_attemptStreamWithRetry(
        streamIndex: streamIndex,
        host: host,
        port: port,
        sizeMB: sizePerStream,
        deadline: deadline,
        onProgress: (bytes) {
          streamProgress[streamIndex] = bytes;
          int total = streamProgress.reduce((a, b) => a + b);
          progress(total);
          _addCheckpoint(total, DateTime.now());
        },
        enableRetry: enableRetry,
        retryStatus: retryStatus,
      ));
    }

    try {
      await Future.wait(futures);

      if (!_isCancelled) {
        DateTime endTime = DateTime.now();
        int totalBytes = streamProgress.reduce((a, b) => a + b);
        double duration = endTime.difference(startTime).inMicroseconds / 1000000.0;

        final (double p50, double p90) = _calculateSlidingWindowSpeed();
        double speed = p50 > 0
            ? p50
            : (totalBytes / 1024 / 1024) / (duration > 0 ? duration : 0.0001);

        var eval = GigabitEvaluator.evaluate(speed, l10n, mode: evaluationMode);
        var result = SpeedTestResult(
          transferredBytes: totalBytes,
          duration: duration,
          startedAt: startTime,
          endedAt: endTime,
          evaluation: eval,
          p50SpeedMBps: p50 > 0 ? p50 : null,
          p90SpeedMBps: p90 > 0 ? p90 : null,
        );
        completion(Result.success(result));
      }
    } catch (e) {
      if (!_isCancelled) {
        completion(Result.failure(e));
      }
    }
  }

  // --- Helpers ---

  void _addCheckpoint(int cumulativeBytes, DateTime now) {
    if (_testStartTime == null) return;
    int ms = now.difference(_testStartTime!).inMilliseconds;
    // Enforce minimum 80ms between checkpoints to avoid excessive density
    if (_checkpoints.isNotEmpty && ms - _checkpoints.last.$1 < 80) return;
    _checkpoints.add((ms, cumulativeBytes));
  }

  /// Sliding Window Sustained Throughput algorithm.
  ///
  /// Records cumulative byte checkpoints, then computes speed over overlapping
  /// 500ms windows after a 1500ms warmup (to exclude TCP Slow Start).
  /// Returns (p50, p90) where p50 is the median sustained speed and p90 is
  /// the 90th-percentile peak sustained speed, both in MB/s.
  (double p50, double p90) _calculateSlidingWindowSpeed() {
    if (_checkpoints.length < 4) return (0, 0);

    const int warmupMs = 1500;   // Discard first 1.5s for TCP Slow Start
    const int windowMs = 500;    // Sliding window width
    const int minWindowMs = 100; // Minimum actual window width to include

    final List<double> windowSpeeds = [];

    for (int i = 1; i < _checkpoints.length; i++) {
      final (int ti, int bi) = _checkpoints[i];
      if (ti < warmupMs) continue;

      // Find the most recent checkpoint at or before (ti - windowMs)
      int targetT = ti - windowMs;
      int j = i - 1;
      while (j > 0 && _checkpoints[j].$1 > targetT) j--;

      final (int tj, int bj) = _checkpoints[j];
      int dtMs = ti - tj;
      if (dtMs < minWindowMs) continue;

      int diffBytes = bi - bj;
      if (diffBytes <= 0) continue;

      double speedMBps = (diffBytes / 1024 / 1024) / (dtMs / 1000.0);
      // Filter physically impossible values (> 10 Gbps)
      if (speedMBps > 0 && speedMBps < 10000) {
        windowSpeeds.add(speedMBps);
      }
    }

    if (windowSpeeds.isEmpty) return (0, 0);

    windowSpeeds.sort();
    int n = windowSpeeds.length;
    double p50 = windowSpeeds[n ~/ 2];
    double p90 = windowSpeeds[(n * 0.9).floor().clamp(0, n - 1)];
    return (p50, p90);
  }

  Future<void> _attemptStreamWithRetry({
    required int streamIndex,
    required String host,
    required int port,
    required int sizeMB,
    required DateTime? deadline,
    required Function(int) onProgress,
    required bool enableRetry,
    Function(int, int)? retryStatus,
  }) async {
    int attempts = 0;
    int maxAttempts = enableRetry ? maxRetryAttempts : 1;

    while (attempts < maxAttempts && !_isCancelled) {
      attempts++;

      try {
        if (attempts > 1 && retryStatus != null) {
          retryStatus(attempts, maxAttempts);
        }

        await _attemptSingleStream(
          streamIndex: streamIndex,
          host: host,
          port: port,
          sizeMB: sizeMB,
          deadline: deadline,
          onProgress: onProgress,
        );
        return; // Success
      } catch (e) {
        if (attempts >= maxAttempts || _isCancelled) {
          rethrow;
        }

        double delay = retryDelaySeconds + (attempts * retryDelayIncrement);
        if (delay > 10) delay = 10;
        await Future.delayed(Duration(milliseconds: (delay * 1000).toInt()));
      }
    }
  }

  Future<void> _attemptSingleStream({
    required int streamIndex,
    required String host,
    required int port,
    required int sizeMB,
    required DateTime? deadline,
    required Function(int) onProgress,
  }) async {
    if (_isCancelled) return;

    final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    socket.setOption(SocketOption.tcpNoDelay, true);
    _clientSockets.add(socket);

    try {
      await _sendDataStream(
        socket: socket,
        totalSizeMB: sizeMB,
        deadline: deadline,
        progress: onProgress,
      );
    } catch (e) {
      socket.destroy();
      _clientSockets.remove(socket);
      rethrow;
    }
  }

  Future<void> _sendDataStream({
    required Socket socket,
    required int totalSizeMB,
    required Function(int) progress,
    DateTime? deadline,
  }) async {
    int targetBytes = totalSizeMB * 1024 * 1024;
    int sentBytes = 0;

    const int chunkSize = 256 * 1024;
    final chunk = Uint8List(chunkSize);
    chunk.fillRange(0, chunkSize, 0x58);

    DateTime lastProgressTime = DateTime.now();

    try {
      while (!_isCancelled) {
        // Time-bounded mode: stop when deadline is reached
        if (deadline != null && DateTime.now().isAfter(deadline)) break;
        // Size-bounded mode: stop when target bytes reached
        if (deadline == null && sentBytes >= targetBytes) break;

        int toSend = deadline == null
            ? (targetBytes - sentBytes < chunkSize ? targetBytes - sentBytes : chunkSize)
            : chunkSize;

        socket.add(toSend == chunkSize ? chunk : chunk.sublist(0, toSend));
        sentBytes += toSend;

        DateTime now = DateTime.now();
        if (now.difference(lastProgressTime).inMilliseconds > 100) {
          progress(sentBytes);
          lastProgressTime = now;
          await Future.delayed(Duration.zero);
        }
      }

      // Final progress update
      progress(sentBytes);

      await socket.flush();
      await socket.close();
      _clientSockets.remove(socket);
    } catch (e) {
      socket.destroy();
      _clientSockets.remove(socket);
      rethrow;
    }
  }
}

// Simple Result wrapper
class Result<T> {
  final T? value;
  final Object? error;

  Result.success(this.value) : error = null;
  Result.failure(this.error) : value = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
