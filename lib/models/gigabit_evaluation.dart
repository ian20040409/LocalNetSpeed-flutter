enum EvaluationMode {
  gigabit("Gigabit 有線"),
  wifi("WiFi 區網");

  final String label;
  const EvaluationMode(this.label);
}

class GigabitEvaluation {
  final double speedMBps;
  final double performancePercent;
  final String rating;
  final String icon;
  final String message;
  final List<String> suggestions;
  final EvaluationMode mode;

  GigabitEvaluation({
    required this.speedMBps,
    required this.performancePercent,
    required this.rating,
    required this.icon,
    required this.message,
    required this.suggestions,
    required this.mode,
  });
}
