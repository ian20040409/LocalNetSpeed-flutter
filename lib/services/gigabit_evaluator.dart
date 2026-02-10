import '../models/gigabit_evaluation.dart';

class GigabitEvaluator {
  static const double theoreticalMBps = 125.0;
  static const double practicalThreshold = 100.0;

  static GigabitEvaluation evaluate(double speedMBps) {
    final percent = (speedMBps / theoreticalMBps) * 100.0;
    String rating;
    String message;

    if (speedMBps >= practicalThreshold) {
      rating = "優秀 ✅";
      message = "恭喜！您的網路已達到 Gigabit 等級效能";
    } else if (speedMBps >= 80) {
      rating = "良好 ⚡";
      message = "接近 Gigabit 效能，但仍有提升空間";
    } else if (speedMBps >= 50) {
      rating = "一般 ⚠️";
      message = "網路速度一般，建議檢查網路設備或連線品質";
    } else if (speedMBps >= 10) {
      rating = "偏慢 🐌";
      message = "網路速度偏慢，可能未使用 Gigabit 設備";
    } else {
      rating = "很慢 🚫";
      message = "網路速度很慢，建議檢查網路連線問題";
    }

    List<String> suggestions = [];
    if (speedMBps < practicalThreshold) {
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
      message: message,
      suggestions: suggestions,
    );
  }
}
