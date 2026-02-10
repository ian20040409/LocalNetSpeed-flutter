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
  Socket? _clientSocket;
  bool _isCancelled = false;

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
      
      try {
        _clientSocket?.destroy();
        _clientSocket = null;
      } catch (_) {}
    }
    
    _currentRetryAttempt = 0;
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

      int totalBytes = 0;
      DateTime startTime = DateTime.now(); // Roughly when connected

      socket.listen(
        (List<int> data) {
          totalBytes += data.length;
          progress(totalBytes);
        },
        onError: (error) {
          socket.destroy();
          // We don't fail the whole server on one connection error
        },
        onDone: () {
          DateTime endTime = DateTime.now();
          double duration = endTime.difference(startTime).inMicroseconds / 1000000.0;
          double speed = (totalBytes / 1024 / 1024) / (duration > 0 ? duration : 0.0001);
          var eval = GigabitEvaluator.evaluate(speed);
          var result = SpeedTestResult(
            transferredBytes: totalBytes,
            duration: duration,
            startedAt: startTime,
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
  }) async {
    if (kIsWeb) {
      completion(Result.failure(Exception("Web platform does not support TCP Client Sockets.")));
      return;
    }

    _isCancelled = false;
    _currentRetryAttempt = 0;

    _attemptConnection(
      host: host,
      port: port,
      totalSizeMB: totalSizeMB,
      progress: progress,
      completion: completion,
      retryStatus: retryStatus,
      enableRetry: enableRetry,
    );
  }

  Future<void> _attemptConnection({
    required String host,
    required int port,
    required int totalSizeMB,
    required Function(int) progress,
    required Function(Result<SpeedTestResult>) completion,
    Function(int, int)? retryStatus,
    required bool enableRetry,
  }) async {
    if (_isCancelled) {
      completion(Result.failure(Exception("Cancelled")));
      return;
    }

    _currentRetryAttempt++;
    if (retryStatus != null) {
      retryStatus(_currentRetryAttempt, maxRetryAttempts);
    }

    // Set connection timeout
    bool timedOut = false;
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(const Duration(seconds: 30), () {
      timedOut = true;
      _clientSocket?.destroy(); // This triggers onError or onDone
    });

    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _connectionTimeoutTimer?.cancel();
      
      if (timedOut || _isCancelled) {
        socket.destroy();
        return;
      }

      _clientSocket = socket;
      
      // Send data
      await _sendData(
        socket: socket,
        totalSizeMB: totalSizeMB,
        progress: progress,
        completion: completion,
      );

    } catch (e) {
      _connectionTimeoutTimer?.cancel();
      _handleConnectionFailure(
        host: host,
        port: port,
        totalSizeMB: totalSizeMB,
        progress: progress,
        completion: completion,
        retryStatus: retryStatus,
        enableRetry: enableRetry,
        error: e,
      );
    }
  }

  Future<void> _sendData({
    required Socket socket,
    required int totalSizeMB,
    required Function(int) progress,
    required Function(Result<SpeedTestResult>) completion,
  }) async {
    int targetBytes = totalSizeMB * 1024 * 1024;
    int sentBytes = 0;
    
    // Prepare chunk
    final chunk = Uint8List(defaultChunkSize);
    chunk.fillRange(0, defaultChunkSize, 0x58);

    DateTime startTime = DateTime.now();

    try {
      while (sentBytes < targetBytes && !_isCancelled) {
        int remaining = targetBytes - sentBytes;
        int toSend = remaining < defaultChunkSize ? remaining : defaultChunkSize;
        
        // If we are sending a partial chunk, slice it
        if (toSend < defaultChunkSize) {
           socket.add(chunk.sublist(0, toSend));
        } else {
           socket.add(chunk);
        }
        
        sentBytes += toSend;
        progress(sentBytes);

        // Yield to event loop to allow socket to drain and UI to update
        await Future.delayed(Duration.zero);
      }

      if (_isCancelled) {
         socket.destroy();
         completion(Result.failure(Exception("Cancelled")));
         return;
      }

      await socket.flush();
      DateTime endTime = DateTime.now();
      
      // Close socket nicely
      await socket.close();
      _clientSocket = null;

      double duration = endTime.difference(startTime).inMicroseconds / 1000000.0;
      double speed = (sentBytes / 1024 / 1024) / (duration > 0 ? duration : 0.0001);
      
      var eval = GigabitEvaluator.evaluate(speed);
      var result = SpeedTestResult(
        transferredBytes: sentBytes,
        duration: duration,
        startedAt: startTime,
        endedAt: endTime,
        evaluation: eval,
      );
      
      completion(Result.success(result));

    } catch (e) {
      socket.destroy();
      completion(Result.failure(e));
    }
  }

  void _handleConnectionFailure({
    required String host,
    required int port,
    required int totalSizeMB,
    required Function(int) progress,
    required Function(Result<SpeedTestResult>) completion,
    Function(int, int)? retryStatus,
    required bool enableRetry,
    required Object error,
  }) {
    _clientSocket = null;

    if (enableRetry && _currentRetryAttempt < maxRetryAttempts && !_isCancelled) {
      double baseDelay = retryDelaySeconds + ((_currentRetryAttempt - 1) * retryDelayIncrement);
      double delay = baseDelay > 10.0 ? 10.0 : baseDelay;

      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(milliseconds: (delay * 1000).toInt()), () {
        _attemptConnection(
          host: host,
          port: port,
          totalSizeMB: totalSizeMB,
          progress: progress,
          completion: completion,
          retryStatus: retryStatus,
          enableRetry: enableRetry,
        );
      });
    } else {
      String msg;
      if (!enableRetry) {
        msg = "連線失敗：無法連接到伺服器。錯誤：$error";
      } else if (_currentRetryAttempt >= maxRetryAttempts) {
        msg = "連線失敗：已達到最大重試次數 ($maxRetryAttempts 次)。最後錯誤：$error";
      } else {
        msg = error.toString();
      }
      completion(Result.failure(Exception(msg)));
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
