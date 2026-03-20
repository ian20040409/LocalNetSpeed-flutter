import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/gigabit_evaluation.dart';
import '../models/gigabit_evaluation_l10n.dart';
import '../models/speed_test_result.dart';
import '../view_models/content_view_model.dart';
import 'speed_gauge_view.dart';

class ResultWindow extends StatelessWidget {
  final SpeedTestResult result;
  final SpeedUnit unit;

  const ResultWindow({
    super.key,
    required this.result,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpeedGaugeView(
                speed: unit.convertFromMBps(result.speedMBps),
                unit: unit.label,
                maxSpeed: _getMaxSpeed(unit, result.evaluation.mode),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    result.evaluation.rating,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  _buildRatingIcon(result.evaluation.icon),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                result.evaluation.mode.localizedLabel(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                result.evaluation.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatBadge(
                          context,
                          Icons.swap_vert,
                          l10n.resultTotal,
                          "${(result.transferredBytes / 1024 / 1024).toStringAsFixed(1)} MB",
                        ),
                      ),
                      Container(width: 1, color: Colors.grey.withOpacity(0.3)),
                      Expanded(
                        child: _buildStatBadge(
                          context,
                          Icons.access_time,
                          l10n.resultDuration,
                          l10n.resultDurationValue(result.duration.toStringAsFixed(2)),
                        ),
                      ),
                      if (result.p90SpeedMBps != null) ...[
                        Container(width: 1, color: Colors.grey.withOpacity(0.3)),
                        Expanded(
                          child: _buildStatBadge(
                            context,
                            Icons.speed,
                            "P90",
                            "${unit.convertFromMBps(result.p90SpeedMBps!).toStringAsFixed(1)} ${unit.label}",
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.closeButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingIcon(String emojiIcon) {
    switch (emojiIcon) {
      case "✅":
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case "⚡":
        return const Icon(Icons.bolt, color: Colors.orange, size: 28);
      case "⚠️":
        return const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28);
      case "🐌":
        return const Icon(Icons.slow_motion_video, color: Colors.deepOrange, size: 28);
      case "🚫":
        return const Icon(Icons.cancel, color: Colors.red, size: 28);
      case "📶":
        return const Icon(Icons.signal_wifi_4_bar, color: Colors.green, size: 28);
      default:
        return const Icon(Icons.help_outline, size: 28);
    }
  }

  double _getMaxSpeed(SpeedUnit unit, EvaluationMode mode) {
    if (mode == EvaluationMode.wifi) {
      switch (unit) {
        case SpeedUnit.mbps: return 1200;
        case SpeedUnit.gbps: return 1.2;
        case SpeedUnit.mbs: return 150;
        case SpeedUnit.kbps: return 1200000;
      }
    }
    switch (unit) {
      case SpeedUnit.mbps: return 1000;
      case SpeedUnit.gbps: return 1;
      case SpeedUnit.mbs: return 125;
      case SpeedUnit.kbps: return 1000000;
    }
  }
}
