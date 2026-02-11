import 'package:flutter/material.dart';
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
                maxSpeed: _getMaxSpeed(unit),
              ),
              const SizedBox(height: 24),
              Text(
                result.evaluation.rating,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBadge(
                      context,
                      Icons.swap_vert,
                      "總量",
                      "${(result.transferredBytes / 1024 / 1024).toStringAsFixed(1)} MB",
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                    _buildStatBadge(
                      context,
                      Icons.access_time,
                      "耗時",
                      "${result.duration.toStringAsFixed(2)} 秒",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("關閉"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  double _getMaxSpeed(SpeedUnit unit) {
    switch (unit) {
      case SpeedUnit.mbps: return 1000;
      case SpeedUnit.gbps: return 1;
      case SpeedUnit.mbs: return 125;
      case SpeedUnit.kbps: return 1000000;
    }
  }
}
