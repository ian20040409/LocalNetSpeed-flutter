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
  
  // Speed Sampling for Ookla Algorithm
  final List<double> _speedSamples = [];
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
    _speedSamples.clear();
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
                _lastSampleBytes = 0;
                _lastSampleTime = DateTime.now();
            
                // Divide total size among streams
                int sizePerStream = (totalSizeMB / concurrency).ceil();
                if (sizePerStream < 1) sizePerStream = 1;
            
                List<Future<void>> futures = [];
                // Shared progress tracking
                List<int> streamProgress = List.filled(concurrency, 0);
                DateTime startTime = DateTime.now();
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
                       
                       DateTime now = DateTime.now();
                       if (_lastSampleTime != null && now.difference(_lastSampleTime!).inMilliseconds > 100) {
                          _addSample(total, now);
                       }
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
                if (diffMicros > 0) {
                  int diffBytes = currentBytes - _lastSampleBytes;
                  // Calculate MB/s
                  double speed = (diffBytes / 1024 / 1024) / (diffMicros / 1000000.0);
                  
                  // Filter unrealistic spikes (e.g., > 10 Gbps) caused by buffering
                  if (speed > 0 && speed < 10000) { 
                     _speedSamples.add(speed);
                  }
                  
                  _lastSampleBytes = currentBytes;
                  _lastSampleTime = now;
                }
              }
            
              double _calculateSmartSpeed() {
                if (_speedSamples.isEmpty) return 0.0;
            
                int total = _speedSamples.length;
                // If not enough samples, use simple average
                if (total < 10) {
                   return _speedSamples.reduce((a, b) => a + b) / total;
                }
            
                // 1. Sequential Warm-up (Time-Domain Filter)
                // Ignore the first 20% of samples to filter out TCP Slow Start
                int warmupCount = (total * 0.2).ceil();
                List<double> steadyStateSamples = _speedSamples.sublist(warmupCount);
            
                if (steadyStateSamples.isEmpty) {
                  return _speedSamples.reduce((a, b) => a + b) / total;
                }
            
                // 2. Outlier Filter (Value-Domain Filter)
                // Sort the steady state samples to identify spikes and noise
                steadyStateSamples.sort((a, b) => b.compareTo(a)); // Descending
            
                int steadyTotal = steadyStateSamples.length;
                // Discard Top 10% (OS Buffering Spikes)
                int trimTop = (steadyTotal * 0.1).ceil();
                // Discard Bottom 5% (Minor Noise/Jitter)
                int trimBottom = (steadyTotal * 0.05).ceil();
            
                int start = trimTop;
                int end = steadyTotal - trimBottom;
            
                if (start >= end) {
                   return steadyStateSamples.reduce((a, b) => a + b) / steadyTotal;
                }
            
                // 3. Average the remaining core samples
                double sum = 0;
                int count = 0;
                for (int i = start; i < end; i++) {
                  sum += steadyStateSamples[i];
                  count++;
                }
            
                return count > 0 ? sum / count : 0.0;
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