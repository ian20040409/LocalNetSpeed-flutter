// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'LocalNetSpeed';

  @override
  String get logTooltip => '日誌';

  @override
  String get localIpLabel => '本機 IP';

  @override
  String get ipCopiedSnackbar => 'IP 位址已複製到剪貼板';

  @override
  String get serverIpLabel => '伺服器 IP';

  @override
  String get portLabel => '埠號';

  @override
  String get sizeLabel => '大小 (MB)';

  @override
  String get durationLabel => '時間 (秒)';

  @override
  String get timeBoundedToggle => '時間導向測試';

  @override
  String evaluationModeAutoLabel(String mode) {
    return '評估模式：$mode（自動）';
  }

  @override
  String evaluationModeLabel(String mode) {
    return '評估模式：$mode';
  }

  @override
  String get autoButton => '自動';

  @override
  String get ratingStandardsTooltip => '評分標準';

  @override
  String get serverRunning => '伺服器運行中';

  @override
  String serverConnectionCount(int count) {
    return '（$count 連線）';
  }

  @override
  String get stopButton => '停止';

  @override
  String get forceStopButton => '強制停止';

  @override
  String get startServerButton => '啟動伺服器';

  @override
  String get startTestButton => '開始測試';

  @override
  String get speedTestModeServer => '伺服器';

  @override
  String get speedTestModeClient => '客戶端';

  @override
  String get evaluationModeGigabit => 'Gigabit 有線';

  @override
  String get evaluationModeWifi => 'WiFi 區網';

  @override
  String ratingStandardsTitle(String mode) {
    return '$mode 評分標準';
  }

  @override
  String get wifiThroughputNote => '以實際 TCP 吞吐量為基準，非無線空口速率';

  @override
  String get ratingExcellent => '優秀';

  @override
  String get ratingGood => '良好';

  @override
  String get ratingAverage => '一般';

  @override
  String get ratingSlow => '偏慢';

  @override
  String get ratingVerySlow => '很慢';

  @override
  String get ratingStandardsGigabitRow1Desc => 'Gigabit 等級效能';

  @override
  String get ratingStandardsGigabitRow2Desc => '接近 Gigabit 效能';

  @override
  String get ratingStandardsGigabitRow3Desc => '建議檢查網路設備';

  @override
  String get ratingStandardsGigabitRow4Desc => '可能未使用 Gigabit 設備';

  @override
  String get ratingStandardsGigabitRow5Desc => '建議檢查網路連線';

  @override
  String get ratingStandardsWifiRow1Desc => 'WiFi 6 卓越效能';

  @override
  String get ratingStandardsWifiRow2Desc => 'WiFi 6 正常效能';

  @override
  String get ratingStandardsWifiRow3Desc => 'WiFi 5 或訊號受限';

  @override
  String get ratingStandardsWifiRow4Desc => '訊號弱或距路由器遠';

  @override
  String get ratingStandardsWifiRow5Desc => 'WiFi 4 或訊號極弱';

  @override
  String get closeButton => '關閉';

  @override
  String get resultTotal => '總量';

  @override
  String get resultDuration => '耗時';

  @override
  String resultDurationValue(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get logScreenTitle => '日誌';

  @override
  String get logEmpty => '尚無日誌';

  @override
  String get fetchingIp => '獲取中...';

  @override
  String get ipUnavailable => '無法取得';

  @override
  String get statusNotStarted => '尚未開始';

  @override
  String get statusPreparing => '準備中...';

  @override
  String get statusConnecting => '正在連線...';

  @override
  String get statusCancelled => '已取消';

  @override
  String get statusDone => '完成';

  @override
  String get statusWaitingConnection => '等待連線...';

  @override
  String get statusForceStopped => '伺服器已強制停止';

  @override
  String get statusErrorPort => '埠號不正確';

  @override
  String get statusErrorNoHost => '請輸入伺服器 IP';

  @override
  String get statusErrorDuration => '測試時間不正確';

  @override
  String get statusErrorSize => '資料大小不正確';

  @override
  String statusError(String message) {
    return '錯誤：$message';
  }

  @override
  String statusReceived(String mb) {
    return '已接收 $mb MB';
  }

  @override
  String statusSent(String mb) {
    return '已傳送 $mb MB';
  }

  @override
  String statusProgress(String percent) {
    return '進度 $percent%';
  }

  @override
  String statusRetrying(int attempt, int max) {
    return '重試連線 ($attempt/$max)...';
  }

  @override
  String statusWaitingServer(int attempt, int max) {
    return '等待伺服器啟動... ($attempt/$max)';
  }

  @override
  String logServerStarted(int port) {
    return '伺服器啟動，埠 $port，等待連線...';
  }

  @override
  String logNewConnection(int count) {
    return '新連線 #$count';
  }

  @override
  String logClientConnectingTimeBounded(String host, int port, int dur) {
    return '客戶端連線到 $host:$port，時間導向測試 ${dur}s (4 平行串流)...';
  }

  @override
  String logClientConnectingSizeBounded(String host, int port, int size) {
    return '客戶端連線到 $host:$port，傳送 $size MB (4 平行串流)...';
  }

  @override
  String logRetryAttempt(int attempt) {
    return '第 $attempt 次連線嘗試...';
  }

  @override
  String logWaitingServer(int attempt) {
    return '持續等待伺服器啟動... (第 $attempt 次嘗試)';
  }

  @override
  String get logCancelled => '測試已取消';

  @override
  String get logForceStopped => '伺服器已強制停止';

  @override
  String logError(String message) {
    return '錯誤：$message';
  }

  @override
  String get logServerContinues => '--- 伺服器繼續運行，等待下一個連線 ---';

  @override
  String get logResultHeader => '--- 測試結果 ---';

  @override
  String logResultTotal(String mb) {
    return '總量: $mb MB';
  }

  @override
  String logResultDuration(String sec) {
    return '耗時: $sec 秒';
  }

  @override
  String logResultSpeed(String speed, String unit) {
    return '速度: $speed $unit';
  }

  @override
  String logResultP50(String speed, String unit) {
    return 'P50 (中位數持續): $speed $unit';
  }

  @override
  String logResultP90(String speed, String unit) {
    return 'P90 (峰值持續): $speed $unit';
  }

  @override
  String logResultEvalHeader(String mode) {
    return '--- $mode 評估 ---';
  }

  @override
  String logResultActualSpeed(String speed, String unit) {
    return '實際速度: $speed $unit';
  }

  @override
  String logResultTheoretical(String speed, String unit) {
    return '理論: $speed $unit';
  }

  @override
  String logResultPercent(String percent) {
    return '達成比例: $percent%';
  }

  @override
  String logResultRating(String icon, String rating) {
    return '評級: $icon $rating';
  }

  @override
  String logResultSuggestion(String message) {
    return '建議: $message';
  }

  @override
  String get logResultImprovements => '改善建議:';

  @override
  String get evalGigabitExcellentMessage => '恭喜！您的網路已達到 Gigabit 等級效能';

  @override
  String get evalGigabitGoodMessage => '接近 Gigabit 效能，但仍有提升空間';

  @override
  String get evalGigabitAverageMessage => '網路速度一般，建議檢查網路設備或連線品質';

  @override
  String get evalGigabitSlowMessage => '網路速度偏慢，可能未使用 Gigabit 設備';

  @override
  String get evalGigabitVerySlowMessage => '網路速度很慢，建議檢查網路連線問題';

  @override
  String get evalGigabitSuggestion1 => '確認使用 Cat5e 或更高等級的網路線';

  @override
  String get evalGigabitSuggestion2 => '檢查網路交換器是否支援 Gigabit';

  @override
  String get evalGigabitSuggestion3 => '確認網路卡設定為 1000 Mbps 全雙工';

  @override
  String get evalGigabitSuggestion4 => '關閉不必要的網路程式和服務';

  @override
  String get evalGigabitSuggestion5 => '檢查是否有網路瓶頸或干擾';

  @override
  String get evalWifiExcellentMessage => 'WiFi 6 效能卓越，接近有線速度';

  @override
  String get evalWifiGoodMessage => 'WiFi 6 效能良好，符合正常預期';

  @override
  String get evalWifiAverageMessage => 'WiFi 速度中等，可能為 WiFi 5 或訊號受限';

  @override
  String get evalWifiSlowMessage => 'WiFi 速度偏慢，建議靠近路由器或排除干擾';

  @override
  String get evalWifiVerySlowMessage => 'WiFi 速度很慢，可能為 WiFi 4 或訊號極弱';

  @override
  String get evalWifiSuggestion1 => '確認路由器支援 WiFi 6 (802.11ax)';

  @override
  String get evalWifiSuggestion2 => '縮短裝置與路由器的距離';

  @override
  String get evalWifiSuggestion3 => '減少同頻段的干擾源（微波爐、藍牙等）';

  @override
  String get evalWifiSuggestion4 => '確認連接到 5GHz 頻段而非 2.4GHz';

  @override
  String get evalWifiSuggestion5 => '檢查路由器頻寬設定（建議 80MHz 或 160MHz）';

  @override
  String get evalWifiSuggestion6 => '減少同時連線的裝置數量';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'LocalNetSpeed';

  @override
  String get logTooltip => '日誌';

  @override
  String get localIpLabel => '本機 IP';

  @override
  String get ipCopiedSnackbar => 'IP 位址已複製到剪貼板';

  @override
  String get serverIpLabel => '伺服器 IP';

  @override
  String get portLabel => '埠號';

  @override
  String get sizeLabel => '大小 (MB)';

  @override
  String get durationLabel => '時間 (秒)';

  @override
  String get timeBoundedToggle => '時間導向測試';

  @override
  String evaluationModeAutoLabel(String mode) {
    return '評估模式：$mode（自動）';
  }

  @override
  String evaluationModeLabel(String mode) {
    return '評估模式：$mode';
  }

  @override
  String get autoButton => '自動';

  @override
  String get ratingStandardsTooltip => '評分標準';

  @override
  String get serverRunning => '伺服器運行中';

  @override
  String serverConnectionCount(int count) {
    return '（$count 連線）';
  }

  @override
  String get stopButton => '停止';

  @override
  String get forceStopButton => '強制停止';

  @override
  String get startServerButton => '啟動伺服器';

  @override
  String get startTestButton => '開始測試';

  @override
  String get speedTestModeServer => '伺服器';

  @override
  String get speedTestModeClient => '客戶端';

  @override
  String get evaluationModeGigabit => 'Gigabit 有線';

  @override
  String get evaluationModeWifi => 'WiFi 區網';

  @override
  String ratingStandardsTitle(String mode) {
    return '$mode 評分標準';
  }

  @override
  String get wifiThroughputNote => '以實際 TCP 吞吐量為基準，非無線空口速率';

  @override
  String get ratingExcellent => '優秀';

  @override
  String get ratingGood => '良好';

  @override
  String get ratingAverage => '一般';

  @override
  String get ratingSlow => '偏慢';

  @override
  String get ratingVerySlow => '很慢';

  @override
  String get ratingStandardsGigabitRow1Desc => 'Gigabit 等級效能';

  @override
  String get ratingStandardsGigabitRow2Desc => '接近 Gigabit 效能';

  @override
  String get ratingStandardsGigabitRow3Desc => '建議檢查網路設備';

  @override
  String get ratingStandardsGigabitRow4Desc => '可能未使用 Gigabit 設備';

  @override
  String get ratingStandardsGigabitRow5Desc => '建議檢查網路連線';

  @override
  String get ratingStandardsWifiRow1Desc => 'WiFi 6 卓越效能';

  @override
  String get ratingStandardsWifiRow2Desc => 'WiFi 6 正常效能';

  @override
  String get ratingStandardsWifiRow3Desc => 'WiFi 5 或訊號受限';

  @override
  String get ratingStandardsWifiRow4Desc => '訊號弱或距路由器遠';

  @override
  String get ratingStandardsWifiRow5Desc => 'WiFi 4 或訊號極弱';

  @override
  String get closeButton => '關閉';

  @override
  String get resultTotal => '總量';

  @override
  String get resultDuration => '耗時';

  @override
  String resultDurationValue(String seconds) {
    return '$seconds 秒';
  }

  @override
  String get logScreenTitle => '日誌';

  @override
  String get logEmpty => '尚無日誌';

  @override
  String get fetchingIp => '獲取中...';

  @override
  String get ipUnavailable => '無法取得';

  @override
  String get statusNotStarted => '尚未開始';

  @override
  String get statusPreparing => '準備中...';

  @override
  String get statusConnecting => '正在連線...';

  @override
  String get statusCancelled => '已取消';

  @override
  String get statusDone => '完成';

  @override
  String get statusWaitingConnection => '等待連線...';

  @override
  String get statusForceStopped => '伺服器已強制停止';

  @override
  String get statusErrorPort => '埠號不正確';

  @override
  String get statusErrorNoHost => '請輸入伺服器 IP';

  @override
  String get statusErrorDuration => '測試時間不正確';

  @override
  String get statusErrorSize => '資料大小不正確';

  @override
  String statusError(String message) {
    return '錯誤：$message';
  }

  @override
  String statusReceived(String mb) {
    return '已接收 $mb MB';
  }

  @override
  String statusSent(String mb) {
    return '已傳送 $mb MB';
  }

  @override
  String statusProgress(String percent) {
    return '進度 $percent%';
  }

  @override
  String statusRetrying(int attempt, int max) {
    return '重試連線 ($attempt/$max)...';
  }

  @override
  String statusWaitingServer(int attempt, int max) {
    return '等待伺服器啟動... ($attempt/$max)';
  }

  @override
  String logServerStarted(int port) {
    return '伺服器啟動，埠 $port，等待連線...';
  }

  @override
  String logNewConnection(int count) {
    return '新連線 #$count';
  }

  @override
  String logClientConnectingTimeBounded(String host, int port, int dur) {
    return '客戶端連線到 $host:$port，時間導向測試 ${dur}s (4 平行串流)...';
  }

  @override
  String logClientConnectingSizeBounded(String host, int port, int size) {
    return '客戶端連線到 $host:$port，傳送 $size MB (4 平行串流)...';
  }

  @override
  String logRetryAttempt(int attempt) {
    return '第 $attempt 次連線嘗試...';
  }

  @override
  String logWaitingServer(int attempt) {
    return '持續等待伺服器啟動... (第 $attempt 次嘗試)';
  }

  @override
  String get logCancelled => '測試已取消';

  @override
  String get logForceStopped => '伺服器已強制停止';

  @override
  String logError(String message) {
    return '錯誤：$message';
  }

  @override
  String get logServerContinues => '--- 伺服器繼續運行，等待下一個連線 ---';

  @override
  String get logResultHeader => '--- 測試結果 ---';

  @override
  String logResultTotal(String mb) {
    return '總量: $mb MB';
  }

  @override
  String logResultDuration(String sec) {
    return '耗時: $sec 秒';
  }

  @override
  String logResultSpeed(String speed, String unit) {
    return '速度: $speed $unit';
  }

  @override
  String logResultP50(String speed, String unit) {
    return 'P50 (中位數持續): $speed $unit';
  }

  @override
  String logResultP90(String speed, String unit) {
    return 'P90 (峰值持續): $speed $unit';
  }

  @override
  String logResultEvalHeader(String mode) {
    return '--- $mode 評估 ---';
  }

  @override
  String logResultActualSpeed(String speed, String unit) {
    return '實際速度: $speed $unit';
  }

  @override
  String logResultTheoretical(String speed, String unit) {
    return '理論: $speed $unit';
  }

  @override
  String logResultPercent(String percent) {
    return '達成比例: $percent%';
  }

  @override
  String logResultRating(String icon, String rating) {
    return '評級: $icon $rating';
  }

  @override
  String logResultSuggestion(String message) {
    return '建議: $message';
  }

  @override
  String get logResultImprovements => '改善建議:';

  @override
  String get evalGigabitExcellentMessage => '恭喜！您的網路已達到 Gigabit 等級效能';

  @override
  String get evalGigabitGoodMessage => '接近 Gigabit 效能，但仍有提升空間';

  @override
  String get evalGigabitAverageMessage => '網路速度一般，建議檢查網路設備或連線品質';

  @override
  String get evalGigabitSlowMessage => '網路速度偏慢，可能未使用 Gigabit 設備';

  @override
  String get evalGigabitVerySlowMessage => '網路速度很慢，建議檢查網路連線問題';

  @override
  String get evalGigabitSuggestion1 => '確認使用 Cat5e 或更高等級的網路線';

  @override
  String get evalGigabitSuggestion2 => '檢查網路交換器是否支援 Gigabit';

  @override
  String get evalGigabitSuggestion3 => '確認網路卡設定為 1000 Mbps 全雙工';

  @override
  String get evalGigabitSuggestion4 => '關閉不必要的網路程式和服務';

  @override
  String get evalGigabitSuggestion5 => '檢查是否有網路瓶頸或干擾';

  @override
  String get evalWifiExcellentMessage => 'WiFi 6 效能卓越，接近有線速度';

  @override
  String get evalWifiGoodMessage => 'WiFi 6 效能良好，符合正常預期';

  @override
  String get evalWifiAverageMessage => 'WiFi 速度中等，可能為 WiFi 5 或訊號受限';

  @override
  String get evalWifiSlowMessage => 'WiFi 速度偏慢，建議靠近路由器或排除干擾';

  @override
  String get evalWifiVerySlowMessage => 'WiFi 速度很慢，可能為 WiFi 4 或訊號極弱';

  @override
  String get evalWifiSuggestion1 => '確認路由器支援 WiFi 6 (802.11ax)';

  @override
  String get evalWifiSuggestion2 => '縮短裝置與路由器的距離';

  @override
  String get evalWifiSuggestion3 => '減少同頻段的干擾源（微波爐、藍牙等）';

  @override
  String get evalWifiSuggestion4 => '確認連接到 5GHz 頻段而非 2.4GHz';

  @override
  String get evalWifiSuggestion5 => '檢查路由器頻寬設定（建議 80MHz 或 160MHz）';

  @override
  String get evalWifiSuggestion6 => '減少同時連線的裝置數量';
}
