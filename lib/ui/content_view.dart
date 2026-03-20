import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/gigabit_evaluation.dart';
import '../models/speed_test_mode.dart';
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

  void _checkResult() {
    if (!mounted) return;
    final vm = context.read<ContentViewModel>();
    if (vm.result != null && !_isShowingResult) {
      _isShowingResult = true;
      showDialog(
        context: context,
        barrierDismissible: false, // User must click close
        builder: (ctx) {
          return ResultWindow(
            result: vm.result!,
            unit: vm.selectedUnit,
          );
        },
      ).then((_) {
        _isShowingResult = false;
        // When dialog closes, we might want to clear result or keep it?
        // If we keep it, this listener might trigger again if we aren't careful?
        // No, listener triggers on notify. If notify happens and result is still there...
        // But we have _isShowingResult flag.
        // It's safer to clear the result in VM so next test can start clean.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("LocalNetSpeed"),
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
            tooltip: "日誌",
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
                              label: Text(m.label),
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
                                    Text("本機 IP", style: Theme.of(context).textTheme.bodySmall),
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
                                    const SnackBar(
                                      content: Text("IP 位址已複製到剪貼板"),
                                      duration: Duration(seconds: 1),
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
                                  decoration: const InputDecoration(
                                    labelText: "伺服器 IP",
                                    border: OutlineInputBorder(),
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
                                  "時間導向測試",
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
                                decoration: const InputDecoration(
                                  labelText: "埠號",
                                  border: OutlineInputBorder(),
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
                                    decoration: const InputDecoration(
                                      labelText: "時間 (秒)",
                                      border: OutlineInputBorder(),
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
                                    decoration: const InputDecoration(
                                      labelText: "大小 (MB)",
                                      border: OutlineInputBorder(),
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
                                    ? "評估模式：${vm.evaluationMode.label}（自動）"
                                    : "評估模式：${vm.evaluationMode.label}",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            if (!vm.autoEvaluationMode)
                              TextButton(
                                onPressed: vm.isRunning ? null : () {
                                  vm.autoEvaluationMode = true;
                                  HapticFeedback.selectionClick();
                                },
                                child: const Text("自動"),
                              ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              color: Colors.grey,
                              tooltip: "評分標準",
                              onPressed: () => _showRatingStandards(context, vm.evaluationMode),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<EvaluationMode>(
                          segments: EvaluationMode.values.map((m) {
                            return ButtonSegment<EvaluationMode>(
                              value: m,
                              label: Text(m.label),
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
                        if (vm.isRunning || (vm.progressText.isNotEmpty && vm.progressText != "尚未開始"))
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
                                      const Text("伺服器運行中", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      if (vm.serverConnectionCount > 0)
                                        Text(" (${vm.serverConnectionCount} 連線)", style: const TextStyle(color: Colors.grey)),
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
                          
                        // Note: Result Card removed, now handled by Dialog
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
                              label: const Text("停止"),
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
                                label: const Text("強制停止"),
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
                              label: Text(vm.mode == SpeedTestMode.server ? "啟動伺服器" : "開始測試"),
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
    final isWifi = mode == EvaluationMode.wifi;
    final rows = isWifi
        ? const [
            ("優秀", "📶", "≥ 600 Mbps", "WiFi 6 卓越效能"),
            ("良好", "✅", "≥ 350 Mbps", "WiFi 6 正常效能"),
            ("一般", "⚡", "≥ 150 Mbps", "WiFi 5 或訊號受限"),
            ("偏慢", "⚠️", "≥ 50 Mbps",  "訊號弱或距路由器遠"),
            ("很慢", "🚫", "< 50 Mbps",  "WiFi 4 或訊號極弱"),
          ]
        : const [
            ("優秀", "✅", "≥ 800 Mbps", "Gigabit 等級效能"),
            ("良好", "⚡", "≥ 640 Mbps", "接近 Gigabit 效能"),
            ("一般", "⚠️", "≥ 400 Mbps", "建議檢查網路設備"),
            ("偏慢", "🐌", "≥ 80 Mbps",  "可能未使用 Gigabit 設備"),
            ("很慢", "🚫", "< 80 Mbps",  "建議檢查網路連線"),
          ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isWifi ? Icons.wifi : Icons.cable, size: 20),
            const SizedBox(width: 8),
            Text("${mode.label} 評分標準"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWifi)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "以實際 TCP 吞吐量為基準，非無線空口速率",
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
            child: const Text("關閉"),
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