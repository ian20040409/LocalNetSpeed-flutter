# LocalNetSpeed-flutter

A high-performance local network speed testing tool built with Flutter. This application allows you to measure the data transfer rate between two devices on the same local network using a Client-Server architecture.

[![Related Project](https://img.shields.io/badge/Related-LocalNetSpeed--swift-orange?style=flat-square&logo=swift)](https://github.com/ian20040409/LocalNetSpeed-swift)

## Features

- **Cross-Platform Support**: Measure speeds between Android, iOS, macOS, Windows, and Linux.
- **Client/Server Modes**:
  - **Server Mode**: Host a listener on your device to receive data.
  - **Client Mode**: Connect to a server IP to start the throughput test.
- **Two Test Modes**:
  - **Size-bounded**: Transfer a fixed amount of data (e.g. 100 MB).
  - **Time-bounded**: Transfer continuously for a fixed duration (e.g. 10 seconds).
- **Material You Support**: Dynamic color theming on Android 12+.
- **Real-time Metrics**: Live speed gauge and progress tracking.
- **Dual Evaluation Modes** (auto-detected or manual):
  - **Gigabit 有線**: Evaluates against Gigabit Ethernet thresholds (theoretical 1000 Mbps / 125 MB/s).
  - **WiFi 區網**: Evaluates against real-world WiFi 6 TCP throughput thresholds (≥600 Mbps excellent, ≥350 Mbps good, ≥150 Mbps average), with WiFi-specific ratings and suggestions. Thresholds are calibrated to actual TCP performance, not advertised air speed.
  - The app auto-detects whether the device is on WiFi or wired and selects the appropriate mode. You can manually override at any time.
  - The speed gauge scale adapts to the evaluation mode (1200 Mbps max for WiFi, 1000 Mbps for Gigabit wired).
- **P50 / P90 Statistics**: Reports median sustained speed (P50) and peak sustained speed (P90) for richer insight.

## Speed Calculation Algorithm

This application uses a **Sliding Window Sustained Throughput** algorithm designed for high-bandwidth local networks (LAN). It measures true sustained throughput rather than a simple average.

### How It Works

1. **Checkpoints**: Every ~80 ms, the cumulative bytes transferred and the elapsed time are recorded as a checkpoint.
2. **Sliding Windows**: After the test, a 500 ms sliding window is applied across all checkpoints. Each window computes the instantaneous speed for that 500 ms span.
3. **Warmup Exclusion**: Windows whose right edge falls within the first **1500 ms** are discarded to exclude the TCP Slow Start phase.
4. **Statistics**:
   - **P50 (median)** — the reported headline speed; robust against occasional dips or bursts.
   - **P90 (90th percentile)** — the peak sustained speed; reflects the best throughput the link can maintain.
5. **Fallback**: If insufficient checkpoints are collected (very short tests), the algorithm falls back to the overall bytes-over-time average.

### Why Sliding Windows?

| | Old algorithm | New algorithm |
|---|---|---|
| Sampling | Instantaneous rate per callback | Cumulative bytes checkpoints |
| Windowing | None | 500 ms overlapping windows |
| Warmup | First 20% of samples (count-based) | First 1500 ms (time-based) |
| Outlier handling | IQR filter | Natural — windows smooth bursts |
| Output | Single average speed | P50 + P90 |

Sliding windows are less sensitive to event-loop jitter than per-callback delta rates, and the median (P50) is inherently robust to outliers without requiring an explicit filter.

## CI / CD

Two manually-triggered GitHub Actions workflows are provided under `.github/workflows/`:

| Workflow | File | Description |
|---|---|---|
| **Build & Release** | `build-release.yml` | Builds APK (Android), IPA (iOS, no-codesign), `.zip` (macOS & Windows), `.tar.gz` (Linux), then creates a GitHub Release with all artefacts attached. The version tag is read from `pubspec.yaml` automatically, or you can override it at dispatch time. |
| **Cleanup Old Runs** | `cleanup-runs.yml` | Deletes all workflow run history across every workflow, keeping only the N most recent runs per workflow (default 1). Configure N at dispatch time. |

Both workflows are triggered via **Actions → Run workflow** and never run automatically.

> **iOS note**: The iOS build uses `--no-codesign`. The resulting `.ipa` can be side-loaded but cannot be submitted to the App Store without a valid provisioning profile and certificate.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio / Xcode (for mobile platforms)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/linenyou/LocalNetSpeed-flutter.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Usage

1. **Start the Server**: On one device, select "Server" mode and click "Start Server". Note the displayed Local IP.
2. **Start the Client**: On the second device, select "Client" mode, enter the Server's IP address, and configure the test:
   - **Size-bounded** (default): Enter the data size in MB and click "Start Test".
   - **Time-bounded**: Enable the "時間導向測試" toggle, enter the duration in seconds, and click "Start Test".
3. **Evaluation Mode**: The app auto-detects WiFi vs wired connections and selects the appropriate evaluation mode. You can manually switch between "Gigabit 有線" and "WiFi 區網", or tap "自動" to re-enable auto-detection.
4. **View Results**: The result dialog displays the P50 speed on the gauge, plus a P90 badge alongside total transferred data and duration. The log view shows full P50/P90 details and evaluation based on the selected mode.

## Related Projects

- [LocalNetSpeed-swift](https://github.com/ian20040409/LocalNetSpeed-swift): The original Swift implementation for Apple ecosystem enthusiasts.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
