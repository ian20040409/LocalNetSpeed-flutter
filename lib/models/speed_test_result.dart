import 'gigabit_evaluation.dart';

class SpeedTestResult {
  final int transferredBytes;
  final double duration;
  final DateTime startedAt;
  final DateTime endedAt;
  final GigabitEvaluation evaluation;

  SpeedTestResult({
    required this.transferredBytes,
    required this.duration,
    required this.startedAt,
    required this.endedAt,
    required this.evaluation,
  });

  double get speedMBps {
    if (duration <= 0) return 0;
    return (transferredBytes / 1024 / 1024) / duration;
  }
}
