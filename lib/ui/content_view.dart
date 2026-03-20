import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/gigabit_evaluation.dart';
import '../models/gigabit_evaluation_l10n.dart';
import '../models/speed_test_mode.dart';
import '../models/speed_test_mode_l10n.dart';
import '../services/local_ip_helper.dart';
import '../view_models/content_view_model.dart';
import 'log_view.dart';
import 'result_window.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _sizeController;
  late TextEditingController _durationController;
  bool _isShowingResult = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ContentViewModel>();
    _hostController = TextEditingController(text: vm.host);
    _portController = TextEditingController(text: vm.port);
    _sizeController = TextEditingController(text: vm.sizeMB);
    _durationController = TextEditingController(text: vm.durationSeconds);

    // Listen for result changes
    vm.addListener(_checkResult);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.fetchLocalIP();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ContentViewModel>().setL10n(AppLocalizations.of(context));
  }

  void _checkResult() {
    if (!mounted) return;
    final vm = context.read<ContentViewModel>();
    if (vm.result != null && !_isShowingResult) {
      _isShowingResult = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return ResultWindow(
            result: vm.result!,
            unit: vm.selectedUnit,
          );
        },
      ).then((_) {
        _isShowingResult = false;
        if (mounted) {
          context.read<ContentViewModel>().clearResult();
        }
      });
    }
  }

  @override
  void dispose() {
    context.read<ContentViewModel>().removeListener(_checkResult);
    _hostController.dispose();
    _portController.dispose();
    _sizeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogView()),
              );
            },
            tooltip: l10n.logTooltip,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Consumer<ContentViewModel>(
          builder: (context, vm, child) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mode Picker
                        SegmentedButton<SpeedTestMode>(
                          segments: SpeedTestMode.values.map((m) {
                            return ButtonSegment<SpeedTestMode>(
                              value: m,
                              label: Text(m.localizedLabel(context)),
                              icon: Icon(m == SpeedTestMode.server ? Icons.dns : Icons.phone_iphone),
                            );
                          }).toList(),
                          selected: {vm.mode},
                          onSelectionChanged: (newSelection) {
                            if (!vm.isRunning) {
                              vm.mode = newSelection.first;
                              HapticFeedback.selectionClick();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Local IP
                        _buildCard(
                          child: Row(
                            children: [
                              Icon(
                                vm.detectedConnectionType == ConnectionType.wifi
                                    ? Icons.wifi
                                    : vm.detectedConnectionType == ConnectionType.wired
                                        ? Icons.cable
                                        : Icons.network_wifi,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.localIpLabel, style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      vm.localIP,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: vm.localIP));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.ipCopiedSnackbar),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                  HapticFeedback.lightImpact();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  vm.fetchLocalIP();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Inputs
                        if (vm.mode == SpeedTestMode.client) ...[
                          Row(
                            children: [
                              const Icon(Icons.link, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _hostController,
                                  decoration: InputDecoration(
                                    labelText: l10n.serverIpLabel,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (v) => vm.host = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.paste),
                                onPressed: () async {
                                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                                  if (data?.text != null) {
                                    _hostController.text = data!.text!;
                                    vm.host = data.text!;
                                    HapticFeedback.lightImpact();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Time-bounded mode toggle
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.timeBoundedToggle,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Switch(
                                value: vm.useTimeBounded,
                                onChanged: vm.isRunning ? null : (v) {
                                  vm.useTimeBounded = v;
                                  HapticFeedback.selectionClick();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          children: [
                            const Icon(Icons.numbers, color: Colors.grey),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _portController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.portLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) => vm.port = v,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (vm.mode == SpeedTestMode.client) ...[
                              Icon(
                                vm.useTimeBounded ? Icons.hourglass_empty : Icons.description,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 10),
                              if (vm.useTimeBounded)
                                Expanded(
                                  child: TextField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.durationLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) => vm.durationSeconds = v,
                                  ),
                                )
                              else
                                Expanded(
                                  child: TextField(
                                    controller: _sizeController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.sizeLabel,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) => vm.sizeMB = v,
                                  ),
                                ),
                            ] else
                              const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Unit Picker
                        SegmentedButton<SpeedUnit>(
                          segments: SpeedUnit.values.map((u) {
                            return ButtonSegment<SpeedUnit>(
                              value: u,
                              label: Text(u.label),
                            );
                          }).toList(),
                          selected: {vm.selectedUnit},
                          onSelectionChanged: (newSelection) {
                            vm.selectedUnit = newSelection.first;
                            HapticFeedback.selectionClick();
                          },
                          showSelectedIcon: false,
                        ),
                        const SizedBox(height: 12),

                        // Evaluation Mode
                        Row(
                          children: [
                            Icon(
                              vm.evaluationMode == EvaluationMode.wifi
                                  ? Icons.wifi
                                  : Icons.cable,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                vm.autoEvaluationMode
                                    ? l10n.evaluationModeAutoLabel(vm.evaluationMode.localizedLabel(context))
                                    : l10n.evaluationModeLabel(vm.evaluationMode.localizedLabel(context)),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            if (!vm.autoEvaluationMode)
                              TextButton(
                                onPressed: vm.isRunning ? null : () {
                                  vm.autoEvaluationMode = true;
                                  HapticFeedback.selectionClick();
                                },
                                child: Text(l10n.autoButton),
                              ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              color: Colors.grey,
                              tooltip: l10n.ratingStandardsTooltip,
                              onPressed: () => _showRatingStandards(context, vm.evaluationMode),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<EvaluationMode>(
                          segments: EvaluationMode.values.map((m) {
                            return ButtonSegment<EvaluationMode>(
                              value: m,
                              label: Text(m.localizedLabel(context)),
                              icon: Icon(m == EvaluationMode.gigabit
                                  ? Icons.cable
                                  : Icons.wifi),
                            );
                          }).toList(),
                          selected: {vm.evaluationMode},
                          onSelectionChanged: vm.isRunning ? null : (newSelection) {
                            vm.evaluationMode = newSelection.first;
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(height: 16),

                        // Status
                        if (vm.isRunning || vm.progressText.isNotEmpty)
                          _buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (vm.isRunning && vm.mode == SpeedTestMode.server)
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(l10n.serverRunning, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      if (vm.serverConnectionCount > 0)
                                        Text(l10n.serverConnectionCount(vm.serverConnectionCount), style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                if (vm.isRunning && vm.mode == SpeedTestMode.client) ...[
                                  LinearProgressIndicator(
                                    value: _parseProgress(vm.progressText),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  vm.progressText,
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Actions
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (vm.isRunning) ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                vm.cancel();
                                HapticFeedback.lightImpact();
                              },
                              icon: const Icon(Icons.stop_circle),
                              label: Text(l10n.stopButton),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: const Size(0, 50),
                              ),
                            ),
                          ),
                          if (vm.mode == SpeedTestMode.server) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  vm.forceStopServer();
                                },
                                icon: const Icon(Icons.dangerous),
                                label: Text(l10n.forceStopButton),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  minimumSize: const Size(0, 50),
                                ),
                              ),
                            ),
                          ],
                        ] else
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                vm.start();
                                HapticFeedback.mediumImpact();
                              },
                              icon: Icon(vm.mode == SpeedTestMode.server ? Icons.play_circle : Icons.bolt),
                              label: Text(vm.mode == SpeedTestMode.server ? l10n.startServerButton : l10n.startTestButton),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 50),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRatingStandards(BuildContext context, EvaluationMode mode) {
    final l10n = AppLocalizations.of(context);
    final isWifi = mode == EvaluationMode.wifi;
    final rows = isWifi
        ? [
            (l10n.ratingExcellent, "📶", "≥ 600 Mbps", l10n.ratingStandardsWifiRow1Desc),
            (l10n.ratingGood,      "✅", "≥ 350 Mbps", l10n.ratingStandardsWifiRow2Desc),
            (l10n.ratingAverage,   "⚡", "≥ 150 Mbps", l10n.ratingStandardsWifiRow3Desc),
            (l10n.ratingSlow,      "⚠️", "≥ 50 Mbps",  l10n.ratingStandardsWifiRow4Desc),
            (l10n.ratingVerySlow,  "🚫", "< 50 Mbps",  l10n.ratingStandardsWifiRow5Desc),
          ]
        : [
            (l10n.ratingExcellent, "✅", "≥ 800 Mbps", l10n.ratingStandardsGigabitRow1Desc),
            (l10n.ratingGood,      "⚡", "≥ 640 Mbps", l10n.ratingStandardsGigabitRow2Desc),
            (l10n.ratingAverage,   "⚠️", "≥ 400 Mbps", l10n.ratingStandardsGigabitRow3Desc),
            (l10n.ratingSlow,      "🐌", "≥ 80 Mbps",  l10n.ratingStandardsGigabitRow4Desc),
            (l10n.ratingVerySlow,  "🚫", "< 80 Mbps",  l10n.ratingStandardsGigabitRow5Desc),
          ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isWifi ? Icons.wifi : Icons.cable, size: 20),
            const SizedBox(width: 8),
            Text(l10n.ratingStandardsTitle(mode.localizedLabel(context))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWifi)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.wifiThroughputNote,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows.map((r) {
                return TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.$2, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(r.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Text(r.$3,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(r.$4,
                        style: Theme.of(ctx).textTheme.bodySmall),
                  ),
                ]);
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.closeButton),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  double? _parseProgress(String text) {
    final regex = RegExp(r"([\d\.]+)%");
    final match = regex.firstMatch(text);
    if (match != null) {
      final val = double.tryParse(match.group(1)!);
      if (val != null) return val / 100;
    }
    return null;
  }
}
