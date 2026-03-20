// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LocalNetSpeed';

  @override
  String get logTooltip => 'Logs';

  @override
  String get localIpLabel => 'Local IP';

  @override
  String get ipCopiedSnackbar => 'IP address copied to clipboard';

  @override
  String get serverIpLabel => 'Server IP';

  @override
  String get portLabel => 'Port';

  @override
  String get sizeLabel => 'Size (MB)';

  @override
  String get durationLabel => 'Duration (sec)';

  @override
  String get timeBoundedToggle => 'Time-bounded test';

  @override
  String evaluationModeAutoLabel(String mode) {
    return 'Evaluation mode: $mode (Auto)';
  }

  @override
  String evaluationModeLabel(String mode) {
    return 'Evaluation mode: $mode';
  }

  @override
  String get autoButton => 'Auto';

  @override
  String get ratingStandardsTooltip => 'Rating Standards';

  @override
  String get serverRunning => 'Server running';

  @override
  String serverConnectionCount(int count) {
    return ' ($count connection)';
  }

  @override
  String get stopButton => 'Stop';

  @override
  String get forceStopButton => 'Force Stop';

  @override
  String get startServerButton => 'Start Server';

  @override
  String get startTestButton => 'Start Test';

  @override
  String get speedTestModeServer => 'Server';

  @override
  String get speedTestModeClient => 'Client';

  @override
  String get evaluationModeGigabit => 'Gigabit LAN';

  @override
  String get evaluationModeWifi => 'WiFi LAN';

  @override
  String ratingStandardsTitle(String mode) {
    return '$mode Rating Standards';
  }

  @override
  String get wifiThroughputNote =>
      'Based on actual TCP throughput, not wireless air speed';

  @override
  String get ratingExcellent => 'Excellent';

  @override
  String get ratingGood => 'Good';

  @override
  String get ratingAverage => 'Average';

  @override
  String get ratingSlow => 'Slow';

  @override
  String get ratingVerySlow => 'Very Slow';

  @override
  String get ratingStandardsGigabitRow1Desc => 'Gigabit-class performance';

  @override
  String get ratingStandardsGigabitRow2Desc => 'Near Gigabit performance';

  @override
  String get ratingStandardsGigabitRow3Desc => 'Check your network equipment';

  @override
  String get ratingStandardsGigabitRow4Desc => 'Possibly no Gigabit equipment';

  @override
  String get ratingStandardsGigabitRow5Desc => 'Check your network connection';

  @override
  String get ratingStandardsWifiRow1Desc => 'WiFi 6 outstanding performance';

  @override
  String get ratingStandardsWifiRow2Desc => 'WiFi 6 typical performance';

  @override
  String get ratingStandardsWifiRow3Desc => 'WiFi 5 or signal-limited';

  @override
  String get ratingStandardsWifiRow4Desc => 'Weak signal or far from router';

  @override
  String get ratingStandardsWifiRow5Desc => 'WiFi 4 or extremely weak signal';

  @override
  String get closeButton => 'Close';

  @override
  String get resultTotal => 'Total';

  @override
  String get resultDuration => 'Duration';

  @override
  String resultDurationValue(String seconds) {
    return '$seconds sec';
  }

  @override
  String get logScreenTitle => 'Logs';

  @override
  String get logEmpty => 'No logs yet';

  @override
  String get fetchingIp => 'Fetching...';

  @override
  String get ipUnavailable => 'Unavailable';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get statusPreparing => 'Preparing...';

  @override
  String get statusConnecting => 'Connecting...';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusDone => 'Done';

  @override
  String get statusWaitingConnection => 'Waiting for connection...';

  @override
  String get statusForceStopped => 'Server force stopped';

  @override
  String get statusErrorPort => 'Invalid port number';

  @override
  String get statusErrorNoHost => 'Please enter server IP';

  @override
  String get statusErrorDuration => 'Invalid test duration';

  @override
  String get statusErrorSize => 'Invalid data size';

  @override
  String statusError(String message) {
    return 'Error: $message';
  }

  @override
  String statusReceived(String mb) {
    return 'Received $mb MB';
  }

  @override
  String statusSent(String mb) {
    return 'Sent $mb MB';
  }

  @override
  String statusProgress(String percent) {
    return 'Progress $percent%';
  }

  @override
  String statusRetrying(int attempt, int max) {
    return 'Retrying connection ($attempt/$max)...';
  }

  @override
  String statusWaitingServer(int attempt, int max) {
    return 'Waiting for server to start... ($attempt/$max)';
  }

  @override
  String logServerStarted(int port) {
    return 'Server started, port $port, waiting for connection...';
  }

  @override
  String logNewConnection(int count) {
    return 'New connection #$count';
  }

  @override
  String logClientConnectingTimeBounded(String host, int port, int dur) {
    return 'Client connecting to $host:$port, time-bounded test ${dur}s (4 parallel streams)...';
  }

  @override
  String logClientConnectingSizeBounded(String host, int port, int size) {
    return 'Client connecting to $host:$port, sending $size MB (4 parallel streams)...';
  }

  @override
  String logRetryAttempt(int attempt) {
    return 'Connection attempt #$attempt...';
  }

  @override
  String logWaitingServer(int attempt) {
    return 'Still waiting for server to start... (attempt $attempt)';
  }

  @override
  String get logCancelled => 'Test cancelled';

  @override
  String get logForceStopped => 'Server force stopped';

  @override
  String logError(String message) {
    return 'Error: $message';
  }

  @override
  String get logServerContinues =>
      '--- Server continuing, waiting for next connection ---';

  @override
  String get logResultHeader => '--- Test Result ---';

  @override
  String logResultTotal(String mb) {
    return 'Total: $mb MB';
  }

  @override
  String logResultDuration(String sec) {
    return 'Duration: $sec sec';
  }

  @override
  String logResultSpeed(String speed, String unit) {
    return 'Speed: $speed $unit';
  }

  @override
  String logResultP50(String speed, String unit) {
    return 'P50 (median sustained): $speed $unit';
  }

  @override
  String logResultP90(String speed, String unit) {
    return 'P90 (peak sustained): $speed $unit';
  }

  @override
  String logResultEvalHeader(String mode) {
    return '--- $mode Evaluation ---';
  }

  @override
  String logResultActualSpeed(String speed, String unit) {
    return 'Actual speed: $speed $unit';
  }

  @override
  String logResultTheoretical(String speed, String unit) {
    return 'Theoretical: $speed $unit';
  }

  @override
  String logResultPercent(String percent) {
    return 'Achievement: $percent%';
  }

  @override
  String logResultRating(String icon, String rating) {
    return 'Rating: $icon $rating';
  }

  @override
  String logResultSuggestion(String message) {
    return 'Suggestion: $message';
  }

  @override
  String get logResultImprovements => 'Improvement tips:';

  @override
  String get evalGigabitExcellentMessage =>
      'Congratulations! Your network has reached Gigabit-class performance';

  @override
  String get evalGigabitGoodMessage =>
      'Near Gigabit performance, but there is still room to improve';

  @override
  String get evalGigabitAverageMessage =>
      'Average network speed, recommend checking equipment or connection quality';

  @override
  String get evalGigabitSlowMessage =>
      'Network speed is slow, possibly not using Gigabit equipment';

  @override
  String get evalGigabitVerySlowMessage =>
      'Network speed is very slow, recommend checking your network connection';

  @override
  String get evalGigabitSuggestion1 =>
      'Confirm you are using Cat5e or higher cable';

  @override
  String get evalGigabitSuggestion2 =>
      'Check that your network switch supports Gigabit';

  @override
  String get evalGigabitSuggestion3 =>
      'Confirm NIC is set to 1000 Mbps full duplex';

  @override
  String get evalGigabitSuggestion4 =>
      'Close unnecessary network programs and services';

  @override
  String get evalGigabitSuggestion5 =>
      'Check for network bottlenecks or interference';

  @override
  String get evalWifiExcellentMessage =>
      'Excellent WiFi 6 performance, close to wired speed';

  @override
  String get evalWifiGoodMessage =>
      'Good WiFi 6 performance, meets normal expectations';

  @override
  String get evalWifiAverageMessage =>
      'Moderate WiFi speed, possibly WiFi 5 or signal-limited';

  @override
  String get evalWifiSlowMessage =>
      'WiFi speed is slow, recommend moving closer to router or eliminating interference';

  @override
  String get evalWifiVerySlowMessage =>
      'WiFi speed is very slow, possibly WiFi 4 or extremely weak signal';

  @override
  String get evalWifiSuggestion1 =>
      'Confirm your router supports WiFi 6 (802.11ax)';

  @override
  String get evalWifiSuggestion2 =>
      'Shorten the distance between device and router';

  @override
  String get evalWifiSuggestion3 =>
      'Reduce interference sources on the same band (microwave, Bluetooth, etc.)';

  @override
  String get evalWifiSuggestion4 =>
      'Confirm connection is on the 5 GHz band, not 2.4 GHz';

  @override
  String get evalWifiSuggestion5 =>
      'Check router bandwidth setting (80 MHz or 160 MHz recommended)';

  @override
  String get evalWifiSuggestion6 =>
      'Reduce the number of simultaneously connected devices';
}
