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

  static GigabitEvaluation evaluate(double speedMBps, {EvaluationMode mode = EvaluationMode.gigabit}) {
    switch (mode) {
      case EvaluationMode.gigabit:
        return _evaluateGigabit(speedMBps);
      case EvaluationMode.wifi:
        return _evaluateWifi(speedMBps);
    }
  }

  static GigabitEvaluation _evaluateGigabit(double speedMBps) {
    final percent = (speedMBps / gigabitTheoreticalMBps) * 100.0;
    String rating;
    String icon;
    String message;

    if (speedMBps >= gigabitPracticalThreshold) {
      rating = "優秀";
      icon = "✅";
      message = "恭喜！您的網路已達到 Gigabit 等級效能";
    } else if (speedMBps >= 80) {
      rating = "良好";
      icon = "⚡";
      message = "接近 Gigabit 效能，但仍有提升空間";
    } else if (speedMBps >= 50) {
      rating = "一般";
      icon = "⚠️";
      message = "網路速度一般，建議檢查網路設備或連線品質";
    } else if (speedMBps >= 10) {
      rating = "偏慢";
      icon = "🐌";
      message = "網路速度偏慢，可能未使用 Gigabit 設備";
    } else {
      rating = "很慢";
      icon = "🚫";
      message = "網路速度很慢，建議檢查網路連線問題";
    }

    List<String> suggestions = [];
    if (speedMBps < gigabitPracticalThreshold) {
      suggestions = [
        "確認使用 Cat5e 或更高等級的網路線",
        "檢查網路交換器是否支援 Gigabit",
        "確認網路卡設定為 1000 Mbps 全雙工",
        "關閉不必要的網路程式和服務",
        "檢查是否有網路瓶頸或干擾"
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

  static GigabitEvaluation _evaluateWifi(double speedMBps) {
    final percent = (speedMBps / wifiTheoreticalMBps) * 100.0;
    String rating;
    String icon;
    String message;

    if (speedMBps >= wifiExcellentMBps) {
      rating = "優秀";
      icon = "📶";
      message = "WiFi 6 效能卓越，接近有線速度";
    } else if (speedMBps >= wifiGoodMBps) {
      rating = "良好";
      icon = "✅";
      message = "WiFi 6 效能良好，符合正常預期";
    } else if (speedMBps >= wifiAverageMBps) {
      rating = "一般";
      icon = "⚡";
      message = "WiFi 速度中等，可能為 WiFi 5 或訊號受限";
    } else if (speedMBps >= wifiSlowMBps) {
      rating = "偏慢";
      icon = "⚠️";
      message = "WiFi 速度偏慢，建議靠近路由器或排除干擾";
    } else {
      rating = "很慢";
      icon = "🚫";
      message = "WiFi 速度很慢，可能為 WiFi 4 或訊號極弱";
    }

    List<String> suggestions = [];
    if (speedMBps < wifiExcellentMBps) {
      suggestions = [
        "確認路由器支援 WiFi 6 (802.11ax)",
        "縮短裝置與路由器的距離",
        "減少同頻段的干擾源（微波爐、藍牙等）",
        "確認連接到 5GHz 頻段而非 2.4GHz",
        "檢查路由器頻寬設定（建議 80MHz 或 160MHz）",
        "減少同時連線的裝置數量",
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
