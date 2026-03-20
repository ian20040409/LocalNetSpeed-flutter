import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// Application name shown in the app bar
  ///
  /// In en, this message translates to:
  /// **'LocalNetSpeed'**
  String get appTitle;

  /// Tooltip for the log icon button in the app bar
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logTooltip;

  /// Label above the local IP address
  ///
  /// In en, this message translates to:
  /// **'Local IP'**
  String get localIpLabel;

  /// Snackbar message after copying IP
  ///
  /// In en, this message translates to:
  /// **'IP address copied to clipboard'**
  String get ipCopiedSnackbar;

  /// TextField label for server IP input
  ///
  /// In en, this message translates to:
  /// **'Server IP'**
  String get serverIpLabel;

  /// TextField label for port number
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// TextField label for transfer size in MB
  ///
  /// In en, this message translates to:
  /// **'Size (MB)'**
  String get sizeLabel;

  /// TextField label for time-bounded duration
  ///
  /// In en, this message translates to:
  /// **'Duration (sec)'**
  String get durationLabel;

  /// Label for the time-bounded mode switch
  ///
  /// In en, this message translates to:
  /// **'Time-bounded test'**
  String get timeBoundedToggle;

  /// Evaluation mode row text when in auto mode
  ///
  /// In en, this message translates to:
  /// **'Evaluation mode: {mode} (Auto)'**
  String evaluationModeAutoLabel(String mode);

  /// Evaluation mode row text when manually set
  ///
  /// In en, this message translates to:
  /// **'Evaluation mode: {mode}'**
  String evaluationModeLabel(String mode);

  /// Button to re-enable automatic evaluation mode selection
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoButton;

  /// Tooltip for the rating standards info icon
  ///
  /// In en, this message translates to:
  /// **'Rating Standards'**
  String get ratingStandardsTooltip;

  /// Status label shown when server is active
  ///
  /// In en, this message translates to:
  /// **'Server running'**
  String get serverRunning;

  /// Appended to serverRunning showing active connection count
  ///
  /// In en, this message translates to:
  /// **' ({count} connection)'**
  String serverConnectionCount(int count);

  /// Stop button label
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// Force stop button label (server mode)
  ///
  /// In en, this message translates to:
  /// **'Force Stop'**
  String get forceStopButton;

  /// Start button label in server mode
  ///
  /// In en, this message translates to:
  /// **'Start Server'**
  String get startServerButton;

  /// Start button label in client mode
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get startTestButton;

  /// SegmentedButton label for server mode
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get speedTestModeServer;

  /// SegmentedButton label for client mode
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get speedTestModeClient;

  /// SegmentedButton label for gigabit evaluation mode
  ///
  /// In en, this message translates to:
  /// **'Gigabit LAN'**
  String get evaluationModeGigabit;

  /// SegmentedButton label for wifi evaluation mode
  ///
  /// In en, this message translates to:
  /// **'WiFi LAN'**
  String get evaluationModeWifi;

  /// Title of the rating standards dialog
  ///
  /// In en, this message translates to:
  /// **'{mode} Rating Standards'**
  String ratingStandardsTitle(String mode);

  /// Note shown in the WiFi rating standards dialog
  ///
  /// In en, this message translates to:
  /// **'Based on actual TCP throughput, not wireless air speed'**
  String get wifiThroughputNote;

  /// Rating tier: excellent
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get ratingExcellent;

  /// Rating tier: good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// Rating tier: average
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get ratingAverage;

  /// Rating tier: slow
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get ratingSlow;

  /// Rating tier: very slow
  ///
  /// In en, this message translates to:
  /// **'Very Slow'**
  String get ratingVerySlow;

  /// Gigabit table row 1 description
  ///
  /// In en, this message translates to:
  /// **'Gigabit-class performance'**
  String get ratingStandardsGigabitRow1Desc;

  /// Gigabit table row 2 description
  ///
  /// In en, this message translates to:
  /// **'Near Gigabit performance'**
  String get ratingStandardsGigabitRow2Desc;

  /// Gigabit table row 3 description
  ///
  /// In en, this message translates to:
  /// **'Check your network equipment'**
  String get ratingStandardsGigabitRow3Desc;

  /// Gigabit table row 4 description
  ///
  /// In en, this message translates to:
  /// **'Possibly no Gigabit equipment'**
  String get ratingStandardsGigabitRow4Desc;

  /// Gigabit table row 5 description
  ///
  /// In en, this message translates to:
  /// **'Check your network connection'**
  String get ratingStandardsGigabitRow5Desc;

  /// WiFi table row 1 description
  ///
  /// In en, this message translates to:
  /// **'WiFi 6 outstanding performance'**
  String get ratingStandardsWifiRow1Desc;

  /// WiFi table row 2 description
  ///
  /// In en, this message translates to:
  /// **'WiFi 6 typical performance'**
  String get ratingStandardsWifiRow2Desc;

  /// WiFi table row 3 description
  ///
  /// In en, this message translates to:
  /// **'WiFi 5 or signal-limited'**
  String get ratingStandardsWifiRow3Desc;

  /// WiFi table row 4 description
  ///
  /// In en, this message translates to:
  /// **'Weak signal or far from router'**
  String get ratingStandardsWifiRow4Desc;

  /// WiFi table row 5 description
  ///
  /// In en, this message translates to:
  /// **'WiFi 4 or extremely weak signal'**
  String get ratingStandardsWifiRow5Desc;

  /// Close button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Stat badge label for total bytes transferred
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get resultTotal;

  /// Stat badge label for test duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get resultDuration;

  /// Formatted duration value
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String resultDurationValue(String seconds);

  /// Title of the log screen
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logScreenTitle;

  /// Placeholder text when log is empty
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logEmpty;

  /// Placeholder while local IP is being detected
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get fetchingIp;

  /// Shown when local IP cannot be obtained
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get ipUnavailable;

  /// Initial progress text before any test
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  /// Progress text during test initialization
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get statusPreparing;

  /// Progress text while attempting to connect
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get statusConnecting;

  /// Progress text after user cancels
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Progress text after successful test completion
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Server status waiting for next client
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection...'**
  String get statusWaitingConnection;

  /// Progress text after force stop
  ///
  /// In en, this message translates to:
  /// **'Server force stopped'**
  String get statusForceStopped;

  /// Validation error for bad port
  ///
  /// In en, this message translates to:
  /// **'Invalid port number'**
  String get statusErrorPort;

  /// Validation error when no host entered
  ///
  /// In en, this message translates to:
  /// **'Please enter server IP'**
  String get statusErrorNoHost;

  /// Validation error for bad duration
  ///
  /// In en, this message translates to:
  /// **'Invalid test duration'**
  String get statusErrorDuration;

  /// Validation error for bad size
  ///
  /// In en, this message translates to:
  /// **'Invalid data size'**
  String get statusErrorSize;

  /// Generic error status
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String statusError(String message);

  /// Server progress showing bytes received
  ///
  /// In en, this message translates to:
  /// **'Received {mb} MB'**
  String statusReceived(String mb);

  /// Client time-bounded progress
  ///
  /// In en, this message translates to:
  /// **'Sent {mb} MB'**
  String statusSent(String mb);

  /// Client size-bounded progress percentage
  ///
  /// In en, this message translates to:
  /// **'Progress {percent}%'**
  String statusProgress(String percent);

  /// Progress text during retry
  ///
  /// In en, this message translates to:
  /// **'Retrying connection ({attempt}/{max})...'**
  String statusRetrying(int attempt, int max);

  /// Progress text during long retry wait
  ///
  /// In en, this message translates to:
  /// **'Waiting for server to start... ({attempt}/{max})'**
  String statusWaitingServer(int attempt, int max);

  /// Log line when server starts
  ///
  /// In en, this message translates to:
  /// **'Server started, port {port}, waiting for connection...'**
  String logServerStarted(int port);

  /// Log line for each new client connection
  ///
  /// In en, this message translates to:
  /// **'New connection #{count}'**
  String logNewConnection(int count);

  /// Log line when client starts a time-bounded test
  ///
  /// In en, this message translates to:
  /// **'Client connecting to {host}:{port}, time-bounded test {dur}s (4 parallel streams)...'**
  String logClientConnectingTimeBounded(String host, int port, int dur);

  /// Log line when client starts a size-bounded test
  ///
  /// In en, this message translates to:
  /// **'Client connecting to {host}:{port}, sending {size} MB (4 parallel streams)...'**
  String logClientConnectingSizeBounded(String host, int port, int size);

  /// Log line for a retry attempt
  ///
  /// In en, this message translates to:
  /// **'Connection attempt #{attempt}...'**
  String logRetryAttempt(int attempt);

  /// Log line during long retry wait
  ///
  /// In en, this message translates to:
  /// **'Still waiting for server to start... (attempt {attempt})'**
  String logWaitingServer(int attempt);

  /// Log line when test is cancelled
  ///
  /// In en, this message translates to:
  /// **'Test cancelled'**
  String get logCancelled;

  /// Log line when server is force stopped
  ///
  /// In en, this message translates to:
  /// **'Server force stopped'**
  String get logForceStopped;

  /// Log line for an error
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String logError(String message);

  /// Log separator after server handles one client
  ///
  /// In en, this message translates to:
  /// **'--- Server continuing, waiting for next connection ---'**
  String get logServerContinues;

  /// Header line in formatted result log
  ///
  /// In en, this message translates to:
  /// **'--- Test Result ---'**
  String get logResultHeader;

  /// Log line for total bytes
  ///
  /// In en, this message translates to:
  /// **'Total: {mb} MB'**
  String logResultTotal(String mb);

  /// Log line for test duration
  ///
  /// In en, this message translates to:
  /// **'Duration: {sec} sec'**
  String logResultDuration(String sec);

  /// Log line for speed
  ///
  /// In en, this message translates to:
  /// **'Speed: {speed} {unit}'**
  String logResultSpeed(String speed, String unit);

  /// Log line for P50
  ///
  /// In en, this message translates to:
  /// **'P50 (median sustained): {speed} {unit}'**
  String logResultP50(String speed, String unit);

  /// Log line for P90
  ///
  /// In en, this message translates to:
  /// **'P90 (peak sustained): {speed} {unit}'**
  String logResultP90(String speed, String unit);

  /// Evaluation section header in log
  ///
  /// In en, this message translates to:
  /// **'--- {mode} Evaluation ---'**
  String logResultEvalHeader(String mode);

  /// Log line for actual speed
  ///
  /// In en, this message translates to:
  /// **'Actual speed: {speed} {unit}'**
  String logResultActualSpeed(String speed, String unit);

  /// Log line for theoretical max speed
  ///
  /// In en, this message translates to:
  /// **'Theoretical: {speed} {unit}'**
  String logResultTheoretical(String speed, String unit);

  /// Log line for achievement percentage
  ///
  /// In en, this message translates to:
  /// **'Achievement: {percent}%'**
  String logResultPercent(String percent);

  /// Log line for rating
  ///
  /// In en, this message translates to:
  /// **'Rating: {icon} {rating}'**
  String logResultRating(String icon, String rating);

  /// Log line for suggestion message
  ///
  /// In en, this message translates to:
  /// **'Suggestion: {message}'**
  String logResultSuggestion(String message);

  /// Header before the improvement suggestions list
  ///
  /// In en, this message translates to:
  /// **'Improvement tips:'**
  String get logResultImprovements;

  /// Gigabit eval: excellent message
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your network has reached Gigabit-class performance'**
  String get evalGigabitExcellentMessage;

  /// Gigabit eval: good message
  ///
  /// In en, this message translates to:
  /// **'Near Gigabit performance, but there is still room to improve'**
  String get evalGigabitGoodMessage;

  /// Gigabit eval: average message
  ///
  /// In en, this message translates to:
  /// **'Average network speed, recommend checking equipment or connection quality'**
  String get evalGigabitAverageMessage;

  /// Gigabit eval: slow message
  ///
  /// In en, this message translates to:
  /// **'Network speed is slow, possibly not using Gigabit equipment'**
  String get evalGigabitSlowMessage;

  /// Gigabit eval: very slow message
  ///
  /// In en, this message translates to:
  /// **'Network speed is very slow, recommend checking your network connection'**
  String get evalGigabitVerySlowMessage;

  /// Gigabit improvement suggestion 1
  ///
  /// In en, this message translates to:
  /// **'Confirm you are using Cat5e or higher cable'**
  String get evalGigabitSuggestion1;

  /// Gigabit improvement suggestion 2
  ///
  /// In en, this message translates to:
  /// **'Check that your network switch supports Gigabit'**
  String get evalGigabitSuggestion2;

  /// Gigabit improvement suggestion 3
  ///
  /// In en, this message translates to:
  /// **'Confirm NIC is set to 1000 Mbps full duplex'**
  String get evalGigabitSuggestion3;

  /// Gigabit improvement suggestion 4
  ///
  /// In en, this message translates to:
  /// **'Close unnecessary network programs and services'**
  String get evalGigabitSuggestion4;

  /// Gigabit improvement suggestion 5
  ///
  /// In en, this message translates to:
  /// **'Check for network bottlenecks or interference'**
  String get evalGigabitSuggestion5;

  /// WiFi eval: excellent message
  ///
  /// In en, this message translates to:
  /// **'Excellent WiFi 6 performance, close to wired speed'**
  String get evalWifiExcellentMessage;

  /// WiFi eval: good message
  ///
  /// In en, this message translates to:
  /// **'Good WiFi 6 performance, meets normal expectations'**
  String get evalWifiGoodMessage;

  /// WiFi eval: average message
  ///
  /// In en, this message translates to:
  /// **'Moderate WiFi speed, possibly WiFi 5 or signal-limited'**
  String get evalWifiAverageMessage;

  /// WiFi eval: slow message
  ///
  /// In en, this message translates to:
  /// **'WiFi speed is slow, recommend moving closer to router or eliminating interference'**
  String get evalWifiSlowMessage;

  /// WiFi eval: very slow message
  ///
  /// In en, this message translates to:
  /// **'WiFi speed is very slow, possibly WiFi 4 or extremely weak signal'**
  String get evalWifiVerySlowMessage;

  /// WiFi improvement suggestion 1
  ///
  /// In en, this message translates to:
  /// **'Confirm your router supports WiFi 6 (802.11ax)'**
  String get evalWifiSuggestion1;

  /// WiFi improvement suggestion 2
  ///
  /// In en, this message translates to:
  /// **'Shorten the distance between device and router'**
  String get evalWifiSuggestion2;

  /// WiFi improvement suggestion 3
  ///
  /// In en, this message translates to:
  /// **'Reduce interference sources on the same band (microwave, Bluetooth, etc.)'**
  String get evalWifiSuggestion3;

  /// WiFi improvement suggestion 4
  ///
  /// In en, this message translates to:
  /// **'Confirm connection is on the 5 GHz band, not 2.4 GHz'**
  String get evalWifiSuggestion4;

  /// WiFi improvement suggestion 5
  ///
  /// In en, this message translates to:
  /// **'Check router bandwidth setting (80 MHz or 160 MHz recommended)'**
  String get evalWifiSuggestion5;

  /// WiFi improvement suggestion 6
  ///
  /// In en, this message translates to:
  /// **'Reduce the number of simultaneously connected devices'**
  String get evalWifiSuggestion6;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
