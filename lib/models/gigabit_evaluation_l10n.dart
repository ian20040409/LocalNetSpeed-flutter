import 'package:flutter/widgets.dart';
import '../generated/l10n/app_localizations.dart';
import 'gigabit_evaluation.dart';

extension EvaluationModeL10n on EvaluationMode {
  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case EvaluationMode.gigabit:
        return l10n.evaluationModeGigabit;
      case EvaluationMode.wifi:
        return l10n.evaluationModeWifi;
    }
  }
}
