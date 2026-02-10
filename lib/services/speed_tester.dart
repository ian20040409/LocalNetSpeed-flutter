import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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
  
  // Speed Sampling for Ookla Algorithm
  List<double> _speedSamples = [];
  int _lastSampleBytes = 0;
  DateTime? _lastSampleTime;

  // Retry state
  int _currentRetryAttempt = 0;
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
    
    _currentRetryAttempt = 0;
    _serverTotalReceivedBytes = 0;
    _serverTestStartTime = null;
    _speedSamples.clear();
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
    _serverTotalReceivedBytes = 0;
    _serverTestStartTime = null;
    _speedSamples.clear();
    _lastSampleBytes = 0;
    _lastSampleTime = DateTime.now();

    int connectionCount = 0;

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

      connectionCount++;
      if (onNewConnection != null) {
        onNewConnection(connectionCount);
      }
      
      // Start global timer on first connection
      if (_serverTestStartTime == null) {
        _serverTestStartTime = DateTime.now();
        _lastSampleTime = _serverTestStartTime;
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
          socket.destroy();
        },
        onDone: () {
          DateTime endTime = DateTime.now();
          DateTime start = _serverTestStartTime ?? endTime;
          double duration = endTime.difference(start).inMicroseconds / 1000000.0;
          
          // Use Ookla algorithm for speed if possible, else fallback to avg
          double speed = _calculateOoklaSpeed();
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
          
          socket.destroy();
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
    _currentRetryAttempt = 0;
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
       futures.add(_attemptSingleStream(
         streamIndex: streamIndex,
         host: host,
         port: port,
         sizeMB: sizePerStream,
         onProgress: (bytes) {
           streamProgress[streamIndex] = bytes;
           int total = streamProgress.reduce((a, b) => a + b);
           progress(total);
           
           // Sample speed (approximate, driven by stream updates)
           // We might sample too often if we do it for every stream update.
           // Better to throttle sampling or do it based on total.
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
        
        // Use Ookla algorithm
        double speed = _calculateOoklaSpeed();
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
      completion(Result.failure(e));
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

  double _calculateOoklaSpeed() {
    if (_speedSamples.isEmpty) return 0.0;

    // Sort descending
    _speedSamples.sort((a, b) => b.compareTo(a));

    int total = _speedSamples.length;
    // If not enough samples, use simple average
    if (total < 5) {
       return _speedSamples.reduce((a, b) => a + b) / total;
    }

    // Ookla Logic:
    // Discard top 10% (outliers)
    // Discard bottom 30% (slow start/ramp up)
    // Average the middle 60%
    
    int start = (total * 0.1).ceil(); // Skip top 10%
    int end = (total * 0.7).floor();  // Stop before bottom 30% (keep top 70% range, but start is shifted)
    
    // Correction:
    // We want the range [10% ... 70%] of the SORTED DESCENDING array.
    // Index 0 is Max.
    // Index Total-1 is Min.
    // 0..10% are largest (discard).
    // 70%..100% are smallest (discard).
    
    // Ensure valid range
    if (start >= end) {
       // Fallback to average of all if filtering removes everything
       return _speedSamples.reduce((a, b) => a + b) / total;
    }

    double sum = 0;
    int count = 0;
    for (int i = start; i < end; i++) {
      sum += _speedSamples[i];
      count++;
    }

    return count > 0 ? sum / count : 0.0;
  }

  Future<void> _attemptSingleStream({
    required int streamIndex,
    required String host,
    required int port,
    required int sizeMB,
    required Function(int) onProgress,
    required bool enableRetry,
    Function(int, int)? retryStatus,
  }) async {
     // Basic retry logic for a single stream is complex to coordinate with global state.
     // For now, if one stream fails, we let it fail or simple retry locally.
     // We will reuse the core logic but adapted for parallel execution.
     
    if (_isCancelled) return;

    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.setOption(SocketOption.tcpNoDelay, true);
      _clientSockets.add(socket);

      await _sendDataStream(
        socket: socket,
        totalSizeMB: sizeMB,
        progress: onProgress,
      );
    } catch (e) {
      // Logic for retry could go here, but for simplicity in multi-stream:
      // We just re-throw or handle quietly.
      if (enableRetry && !_isCancelled) {
         // Simple retry loop for this stream?
         // This is a simplified version.
         rethrow; 
      }
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
