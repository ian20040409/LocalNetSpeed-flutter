import 'package:flutter/widgets.dart';
import '../generated/l10n/app_localizations.dart';
import 'speed_test_mode.dart';

extension SpeedTestModeL10n on SpeedTestMode {
  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case SpeedTestMode.server:
        return l10n.speedTestModeServer;
      case SpeedTestMode.client:
        return l10n.speedTestModeClient;
    }
  }
}
