import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  
  // Speed Sampling for LAN Algorithm
  final List<double> _speedSamples = [];
  final List<int> _sampleTimestampsMs = []; // ms from test start
  DateTime? _testStartTime; // shared start time for both server and client
  int _lastSampleBytes = 0;
  DateTime? _lastSampleTime;

  // Retry state
  Timer? _retryTimer;
  Timer? _connectionTimeoutTimer;

  void cancel() {
    _isCancelled = true;
    _retryTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    
    // Close sockets
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
    _speedSamples.clear();
    _sampleTimestampsMs.clear();
    _lastSampleBytes = 0;
    _lastSampleTime = DateTime.now();
  }

  // --- Server ---

  Future<void> runServer({
    required int port,
    required Function(int) progress,
    required Function(Result<SpeedTestResult>) completion,
    Function(int)? onNewConnection,
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
        _lastSampleTime = _serverTestStartTime;
      }
      _activeConnections++;

      totalConnectionCounter++;
      if (onNewConnection != null) {
        onNewConnection(totalConnectionCounter);
      }
      
      // Optimization: Disable Nagle's algorithm for receiving socket too
      socket.setOption(SocketOption.tcpNoDelay, true);

      DateTime lastProgressTime = DateTime.now();

      socket.listen(
        (List<int> data) {
          _serverTotalReceivedBytes += data.length;
          
          // Throttled UI updates for server side
          DateTime now = DateTime.now();
          if (now.difference(lastProgressTime).inMilliseconds > 100) {
            progress(_serverTotalReceivedBytes);
            
            // Collect Sample
            _addSample(_serverTotalReceivedBytes, now);
            
            lastProgressTime = now;
          }
        },
        onError: (error) {
          _activeConnections--;
          socket.destroy();
           if (_activeConnections == 0) {
             // If all streams failed or closed, we might want to signal something
             // For now, we rely on the logic that at least one might succeed or the user cancels
           }
        },
        onDone: () {
          _activeConnections--;
          socket.destroy();

          // End of session (last stream)
          if (_activeConnections == 0) {
            DateTime endTime = DateTime.now();
            DateTime start = _serverTestStartTime ?? endTime;
            double duration = endTime.difference(start).inMicroseconds / 1000000.0;
            
                      // Use Smart LAN algorithm for speed if possible, else fallback to avg
                      double speed = _calculateSmartSpeed();
                      if (speed == 0) {
                         speed = (_serverTotalReceivedBytes / 1024 / 1024) / (duration > 0 ? duration : 0.0001);
                      }
                      
                      var eval = GigabitEvaluator.evaluate(speed);
                      var result = SpeedTestResult(
                        transferredBytes: _serverTotalReceivedBytes,
                        duration: duration,
                        startedAt: start,
                        endedAt: endTime,
                        evaluation: eval,
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
                required int totalSizeMB,
                required Function(int) progress,
                required Function(Result<SpeedTestResult>) completion,
                Function(int, int)? retryStatus,
                bool enableRetry = true,
                int concurrency = 4, // Default to 4 parallel streams
              }) async {
                if (kIsWeb) {
                  completion(Result.failure(Exception("Web platform does not support TCP Client Sockets.")));
                  return;
                }
            
                _isCancelled = false;
                _clientSockets.clear();
                _speedSamples.clear();
                _sampleTimestampsMs.clear();
                _lastSampleBytes = 0;
                // Divide total size among streams
                int sizePerStream = (totalSizeMB / concurrency).ceil();
                if (sizePerStream < 1) sizePerStream = 1;

                List<Future<void>> futures = [];
                // Shared progress tracking
                List<int> streamProgress = List.filled(concurrency, 0);
                DateTime startTime = DateTime.now();
                _testStartTime = startTime;
                _lastSampleTime = startTime;
            
                for (int i = 0; i < concurrency; i++) {
                   int streamIndex = i;
                   futures.add(_attemptStreamWithRetry(
                     streamIndex: streamIndex,
                     host: host,
                     port: port,
                     sizeMB: sizePerStream,
                     onProgress: (bytes) {
                       streamProgress[streamIndex] = bytes;
                       int total = streamProgress.reduce((a, b) => a + b);
                       progress(total);
                       _addSample(total, DateTime.now());
                     },
                     enableRetry: enableRetry,
                     retryStatus: retryStatus,
                   ));
                }
            
                try {
                  await Future.wait(futures);
                  
                  // All done
                  if (!_isCancelled) {
                    DateTime endTime = DateTime.now();
                    int totalBytes = streamProgress.reduce((a, b) => a + b);
                    double duration = endTime.difference(startTime).inMicroseconds / 1000000.0;
                    
                    // Use Smart LAN algorithm
                    double speed = _calculateSmartSpeed();
                    if (speed == 0) {
                       speed = (totalBytes / 1024 / 1024) / (duration > 0 ? duration : 0.0001);
                    }
                    
                    var eval = GigabitEvaluator.evaluate(speed);
                    var result = SpeedTestResult(
                      transferredBytes: totalBytes,
                      duration: duration,
                      startedAt: startTime,
                      endedAt: endTime,
                      evaluation: eval,
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
              
              void _addSample(int currentBytes, DateTime now) {
                if (_lastSampleTime == null) {
                  _lastSampleTime = now;
                  _lastSampleBytes = currentBytes;
                  return;
                }

                int diffMicros = now.difference(_lastSampleTime!).inMicroseconds;
                // Enforce minimum 50ms between samples to reduce noise
                if (diffMicros < 50000) return;

                int diffBytes = currentBytes - _lastSampleBytes;
                // Guard against negative or zero diffs (e.g., resets)
                if (diffBytes <= 0) {
                  _lastSampleTime = now;
                  return;
                }

                double speed = (diffBytes / 1024 / 1024) / (diffMicros / 1000000.0);

                // Filter unrealistic spikes (> 10 Gbps) caused by OS buffering
                if (speed > 0 && speed < 10000) {
                  _speedSamples.add(speed);
                  // Record ms offset from test start for time-based warmup
                  int msOffset = _testStartTime != null
                      ? now.difference(_testStartTime!).inMilliseconds
                      : 0;
                  _sampleTimestampsMs.add(msOffset);
                }

                _lastSampleBytes = currentBytes;
                _lastSampleTime = now;
              }

              double _calculateSmartSpeed() {
                if (_speedSamples.isEmpty) return 0.0;

                int total = _speedSamples.length;
                if (total < 5) {
                  return _speedSamples.reduce((a, b) => a + b) / total;
                }

                // 1. Warmup filter: discard TCP Slow Start phase
                // Use time-based warmup (first 1s) when test duration > 2s,
                // otherwise fall back to count-based warmup (first 20%).
                List<double> steadySamples;
                int testDurationMs = _sampleTimestampsMs.isNotEmpty
                    ? _sampleTimestampsMs.last
                    : 0;

                if (testDurationMs > 2000 && _sampleTimestampsMs.length == _speedSamples.length) {
                  steadySamples = [
                    for (int i = 0; i < _speedSamples.length; i++)
                      if (_sampleTimestampsMs[i] >= 1000) _speedSamples[i]
                  ];
                } else {
                  int warmupCount = (total * 0.2).ceil();
                  steadySamples = _speedSamples.sublist(warmupCount);
                }

                if (steadySamples.length < 3) {
                  return _speedSamples.reduce((a, b) => a + b) / total;
                }

                // 2. IQR-based outlier removal (more robust than fixed percentile trimming)
                // Adapts to the actual data distribution rather than assuming fixed ratios.
                List<double> sorted = List.from(steadySamples)..sort();
                double q1 = _percentile(sorted, 0.25);
                double q3 = _percentile(sorted, 0.75);
                double iqr = q3 - q1;

                List<double> filtered;
                if (iqr > 0) {
                  double lower = q1 - 1.5 * iqr;
                  double upper = q3 + 1.5 * iqr;
                  filtered = steadySamples.where((s) => s >= lower && s <= upper).toList();
                } else {
                  // IQR == 0 means very stable network; all samples are essentially identical
                  filtered = steadySamples;
                }

                if (filtered.isEmpty) filtered = steadySamples;

                // 3. Mean of the filtered steady-state samples
                return filtered.reduce((a, b) => a + b) / filtered.length;
              }

              /// Linear interpolation percentile on a sorted list.
              double _percentile(List<double> sorted, double p) {
                if (sorted.isEmpty) return 0;
                double idx = p * (sorted.length - 1);
                int lower = idx.floor();
                int upper = idx.ceil();
                if (lower == upper) return sorted[lower];
                return sorted[lower] + (sorted[upper] - sorted[lower]) * (idx - lower);
              }
  Future<void> _attemptStreamWithRetry({
    required int streamIndex,
    required String host,
    required int port,
    required int sizeMB,
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
          onProgress: onProgress,
        );
        return; // Success
      } catch (e) {
        if (attempts >= maxAttempts || _isCancelled) {
          rethrow;
        }
        
        // Wait before retry
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
  }) async {
    int targetBytes = totalSizeMB * 1024 * 1024;
    int sentBytes = 0;
    
    const int optimizedChunkSize = 256 * 1024; 
    final chunk = Uint8List(optimizedChunkSize);
    chunk.fillRange(0, optimizedChunkSize, 0x58);

    DateTime lastProgressTime = DateTime.now();

    try {
      while (sentBytes < targetBytes && !_isCancelled) {
        int remaining = targetBytes - sentBytes;
        int toSend = remaining < optimizedChunkSize ? remaining : optimizedChunkSize;
        
        if (toSend < optimizedChunkSize) {
           socket.add(chunk.sublist(0, toSend));
        } else {
           socket.add(chunk);
        }
        
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