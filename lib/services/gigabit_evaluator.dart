import '../generated/l10n/app_localizations.dart';
import '../models/gigabit_evaluation.dart';

class GigabitEvaluator {
  // Gigabit wired theoretical max
  static const double gigabitTheoreticalMBps = 125.0;
  static const double gigabitPracticalThreshold = 100.0;

  // WiFi 6 (802.11ax) TCP throughput thresholds (calibrated to real-world LAN performance,
  // not air speed — TCP throughput is always significantly lower than advertised air rate)
  static const double wifiTheoreticalMBps = 150.0;  // ~1200 Mbps WiFi 6 theoretical
  static const double wifiExcellentMBps = 75.0;     // ~600 Mbps — WiFi 6 excellent TCP
  static const double wifiGoodMBps = 43.75;          // ~350 Mbps — WiFi 6 typical TCP
  static const double wifiAverageMBps = 18.75;       // ~150 Mbps — WiFi 5 / congested WiFi 6
  static const double wifiSlowMBps = 6.25;           // ~50 Mbps  — WiFi 4 / weak signal

  // Keep backward-compatible alias
  static double get theoreticalMBps => gigabitTheoreticalMBps;
  static double get practicalThreshold => gigabitPracticalThreshold;

  static double theoreticalForMode(EvaluationMode mode) {
    switch (mode) {
      case EvaluationMode.gigabit:
        return gigabitTheoreticalMBps;
      case EvaluationMode.wifi:
        return wifiTheoreticalMBps;
    }
  }

  static GigabitEvaluation evaluate(double speedMBps, AppLocalizations l10n, {EvaluationMode mode = EvaluationMode.gigabit}) {
    switch (mode) {
      case EvaluationMode.gigabit:
        return _evaluateGigabit(speedMBps, l10n);
      case EvaluationMode.wifi:
        return _evaluateWifi(speedMBps, l10n);
    }
  }

  static GigabitEvaluation _evaluateGigabit(double speedMBps, AppLocalizations l10n) {
    final percent = (speedMBps / gigabitTheoreticalMBps) * 100.0;
    String rating;
    String icon;
    String message;

    if (speedMBps >= gigabitPracticalThreshold) {
      rating = l10n.ratingExcellent;
      icon = "✅";
      message = l10n.evalGigabitExcellentMessage;
    } else if (speedMBps >= 80) {
      rating = l10n.ratingGood;
      icon = "⚡";
      message = l10n.evalGigabitGoodMessage;
    } else if (speedMBps >= 50) {
      rating = l10n.ratingAverage;
      icon = "⚠️";
      message = l10n.evalGigabitAverageMessage;
    } else if (speedMBps >= 10) {
      rating = l10n.ratingSlow;
      icon = "🐌";
      message = l10n.evalGigabitSlowMessage;
    } else {
      rating = l10n.ratingVerySlow;
      icon = "🚫";
      message = l10n.evalGigabitVerySlowMessage;
    }

    List<String> suggestions = [];
    if (speedMBps < gigabitPracticalThreshold) {
      suggestions = [
        l10n.evalGigabitSuggestion1,
        l10n.evalGigabitSuggestion2,
        l10n.evalGigabitSuggestion3,
        l10n.evalGigabitSuggestion4,
        l10n.evalGigabitSuggestion5,
      ];
    }

    return GigabitEvaluation(
      speedMBps: speedMBps,
      performancePercent: percent,
      rating: rating,
      icon: icon,
      message: message,
      suggestions: suggestions,
      mode: EvaluationMode.gigabit,
    );
  }

  static GigabitEvaluation _evaluateWifi(double speedMBps, AppLocalizations l10n) {
    final percent = (speedMBps / wifiTheoreticalMBps) * 100.0;
    String rating;
    String icon;
    String message;

    if (speedMBps >= wifiExcellentMBps) {
      rating = l10n.ratingExcellent;
      icon = "📶";
      message = l10n.evalWifiExcellentMessage;
    } else if (speedMBps >= wifiGoodMBps) {
      rating = l10n.ratingGood;
      icon = "✅";
      message = l10n.evalWifiGoodMessage;
    } else if (speedMBps >= wifiAverageMBps) {
      rating = l10n.ratingAverage;
      icon = "⚡";
      message = l10n.evalWifiAverageMessage;
    } else if (speedMBps >= wifiSlowMBps) {
      rating = l10n.ratingSlow;
      icon = "⚠️";
      message = l10n.evalWifiSlowMessage;
    } else {
      rating = l10n.ratingVerySlow;
      icon = "🚫";
      message = l10n.evalWifiVerySlowMessage;
    }

    List<String> suggestions = [];
    if (speedMBps < wifiExcellentMBps) {
      suggestions = [
        l10n.evalWifiSuggestion1,
        l10n.evalWifiSuggestion2,
        l10n.evalWifiSuggestion3,
        l10n.evalWifiSuggestion4,
        l10n.evalWifiSuggestion5,
        l10n.evalWifiSuggestion6,
      ];
    }

    return GigabitEvaluation(
      speedMBps: speedMBps,
      performancePercent: percent,
      rating: rating,
      icon: icon,
      message: message,
      suggestions: suggestions,
      mode: EvaluationMode.wifi,
    );
  }
}
