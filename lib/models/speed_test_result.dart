import 'gigabit_evaluation.dart';

class SpeedTestResult {
  final int transferredBytes;
  final double duration;
  final DateTime startedAt;
  final DateTime endedAt;
  final GigabitEvaluation evaluation;
  final double? p50SpeedMBps; // Median sustained speed (sliding window)
  final double? p90SpeedMBps; // P90 peak sustained speed (sliding window)

  SpeedTestResult({
    required this.transferredBytes,
    required this.duration,
    required this.startedAt,
    required this.endedAt,
    required this.evaluation,
    this.p50SpeedMBps,
    this.p90SpeedMBps,
  });

  // Prefer p50 (sliding window median) over naive average
  double get speedMBps {
    if (p50SpeedMBps != null && p50SpeedMBps! > 0) return p50SpeedMBps!;
    if (duration <= 0) return 0;
    return (transferredBytes / 1024 / 1024) / duration;
  }
}
