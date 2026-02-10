class GigabitEvaluation {
  final double speedMBps;
  final double performancePercent;
  final String rating;
  final String message;
  final List<String> suggestions;

  GigabitEvaluation({
    required this.speedMBps,
    required this.performancePercent,
    required this.rating,
    required this.message,
    required this.suggestions,
  });
}
