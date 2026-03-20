# LocalNetSpeed-flutter

[English](#Features) | [繁體中文](#功能)

[![Related Project](https://img.shields.io/badge/Related-LocalNetSpeed--swift-orange?style=flat-square&logo=swift)](https://github.com/ian20040409/LocalNetSpeed-swift)

---

##### 

A high-performance local network speed testing tool built with Flutter. This application allows you to measure the data transfer rate between two devices on the same local network using a Client-Server architecture.

### Features

- **Multilingual**: Supports English and Traditional Chinese (繁體中文). The app automatically switches based on device language settings.
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
  - **Gigabit LAN**: Evaluates against Gigabit Ethernet thresholds (theoretical 1000 Mbps / 125 MB/s).
  - **WiFi LAN**: Evaluates against real-world WiFi 6 TCP throughput thresholds (≥600 Mbps excellent, ≥350 Mbps good, ≥150 Mbps average), with WiFi-specific ratings and suggestions. Thresholds are calibrated to actual TCP performance, not advertised air speed.
  - The app auto-detects whether the device is on WiFi or wired and selects the appropriate mode. You can manually override at any time.
  - The speed gauge scale adapts to the evaluation mode (1200 Mbps max for WiFi, 1000 Mbps for Gigabit wired).
- **P50 / P90 Statistics**: Reports median sustained speed (P50) and peak sustained speed (P90) for richer insight.

### Speed Rating Standards

#### Gigabit LAN (Wired Ethernet)

Gauge scale: 0 – 1000 Mbps (theoretical max 1000 Mbps / 125 MB/s)

| Rating | Threshold | Description |
|--------|-----------|-------------|
| Excellent ✅ | ≥ 800 Mbps (100 MB/s) | Gigabit-grade performance |
| Good ⚡ | ≥ 640 Mbps (80 MB/s) | Near Gigabit, minor headroom |
| Average ⚠️ | ≥ 400 Mbps (50 MB/s) | Average; check equipment |
| Slow 🐌 | ≥ 80 Mbps (10 MB/s) | Likely non-Gigabit device |
| Very Slow 🚫 | < 80 Mbps (10 MB/s) | Check connection health |

#### WiFi LAN

Gauge scale: 0 – 1200 Mbps (WiFi 6 theoretical max ~1200 Mbps / 150 MB/s)

Thresholds are calibrated to **real-world TCP throughput**, not advertised air speed. TCP throughput is always significantly lower than the WiFi air rate due to protocol overhead, retransmissions, and half-duplex effects.

| Rating | Threshold | Description |
|--------|-----------|-------------|
| Excellent 📶 | ≥ 600 Mbps (75 MB/s) | WiFi 6 excellent TCP performance |
| Good ✅ | ≥ 350 Mbps (43.75 MB/s) | WiFi 6 typical TCP performance |
| Average ⚡ | ≥ 150 Mbps (18.75 MB/s) | WiFi 5 level or congested WiFi 6 |
| Slow ⚠️ | ≥ 50 Mbps (6.25 MB/s) | Weak signal or far from router |
| Very Slow 🚫 | < 50 Mbps (6.25 MB/s) | WiFi 4 or extremely weak signal |

### Speed Calculation Algorithm

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

### Usage

1. **Start the Server**: On one device, select "Server" mode and click "Start Server". Note the displayed Local IP.
2. **Start the Client**: On the second device, select "Client" mode, enter the Server's IP address, and configure the test:
   - **Size-bounded** (default): Enter the data size in MB and click "Start Test".
   - **Time-bounded**: Enable the "Time-bounded test" toggle, enter the duration in seconds, and click "Start Test".
3. **Evaluation Mode**: The app auto-detects WiFi vs wired connections and selects the appropriate evaluation mode. You can manually switch between "Gigabit LAN" and "WiFi LAN", or tap "Auto" to re-enable auto-detection.
4. **View Results**: The result dialog displays the P50 speed on the gauge, plus a P90 badge alongside total transferred data and duration. The log view shows full P50/P90 details and evaluation based on the selected mode.

## Related Projects

- [LocalNetSpeed-swift](https://github.com/ian20040409/LocalNetSpeed-swift): The original Swift implementation for Apple ecosystem enthusiasts.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---


[English](#Features) | [繁體中文](#功能)

一個以 Flutter 構建的高性能區域網路速度測試工具。此應用程式允許您使用用戶端-伺服器架構測量同一區域網路上兩個設備之間的數據傳輸速率。

### 功能

- **多語言支持**：支持英文和繁體中文。應用程式會根據設備語言設置自動切換。
- **跨平台支持**：支持在 Android、iOS、macOS、Windows 和 Linux 之間測量速度。
- **用戶端/伺服器模式**：
  - **伺服器模式**：在您的設備上託管監聽程式以接收數據。
  - **用戶端模式**：連線到伺服器 IP 以啟動吞吐量測試。
- **兩種測試模式**：
  - **大小限制**：轉移固定數量的數據（例如 100 MB）。
  - **時間限制**：以固定時間持續傳輸（例如 10 秒）。
- **Material You 支持**：Android 12+ 上的動態色彩主題。
- **實時指標**：實時速度計量表和進度跟蹤。
- **雙重評估模式**（自動偵測或手動選擇）：
  - **Gigabit 有線**：針對 Gigabit 乙太網路閾值進行評估（理論 1000 Mbps / 125 MB/s）。
  - **WiFi 區網**：針對實際 WiFi 6 TCP 吞吐量閾值進行評估（≥600 Mbps 優秀、≥350 Mbps 良好、≥150 Mbps 一般），包含 WiFi 特定的評級和建議。閾值根據實際 TCP 性能校準，而非廣告的空口速率。
  - 應用程式會自動偵測設備是否在 WiFi 或有線連線上，並選擇適當的模式。您可以隨時手動覆蓋。
  - 速度計量表比例根據評估模式調整（WiFi 最大 1200 Mbps，Gigabit 有線 1000 Mbps）。
- **P50 / P90 統計**：報告中位數持續速度 (P50) 和峰值持續速度 (P90)，提供更豐富的洞察。

### 速度評分標準

#### Gigabit 有線（有線乙太網路）

計量表比例：0 – 1000 Mbps（理論最大值 1000 Mbps / 125 MB/s）

| 評級 | 閾值 | 說明 |
|--------|-----------|-------------|
| 優秀 ✅ | ≥ 800 Mbps (100 MB/s) | Gigabit 等級效能 |
| 良好 ⚡ | ≥ 640 Mbps (80 MB/s) | 接近 Gigabit，輕微提升空間 |
| 一般 ⚠️ | ≥ 400 Mbps (50 MB/s) | 平均；檢查設備 |
| 偏慢 🐌 | ≥ 80 Mbps (10 MB/s) | 可能未使用 Gigabit 設備 |
| 很慢 🚫 | < 80 Mbps (10 MB/s) | 檢查連線品質 |

#### WiFi 區網

計量表比例：0 – 1200 Mbps（WiFi 6 理論最大值 ~1200 Mbps / 150 MB/s）

閾值根據**實際 TCP 吞吐量**校準，而非廣告的空口速率。TCP 吞吐量因協議開銷、重傳和半雙工效果而始終明顯低於 WiFi 空口速率。

| 評級 | 閾值 | 說明 |
|--------|-----------|-------------|
| 優秀 📶 | ≥ 600 Mbps (75 MB/s) | WiFi 6 卓越 TCP 效能 |
| 良好 ✅ | ≥ 350 Mbps (43.75 MB/s) | WiFi 6 正常 TCP 效能 |
| 一般 ⚡ | ≥ 150 Mbps (18.75 MB/s) | WiFi 5 等級或擁塞的 WiFi 6 |
| 偏慢 ⚠️ | ≥ 50 Mbps (6.25 MB/s) | 弱訊號或距離路由器遠 |
| 很慢 🚫 | < 50 Mbps (6.25 MB/s) | WiFi 4 或訊號極弱 |

### 速度計算算法

此應用程式使用為高頻寬區域網路 (LAN) 設計的**滑動窗口持續吞吐量**算法。它測量真正的持續吞吐量，而不是簡單平均值。

#### 工作原理

1. **檢查點**：每約 80 毫秒記錄一次累積傳輸的字節數和經過的時間作為檢查點。
2. **滑動窗口**：測試後，使用 500 毫秒滑動窗口掃過所有檢查點。每個窗口計算該 500 毫秒跨度的瞬時速度。
3. **預熱排除**：右邊界落在前 **1500 毫秒** 內的窗口被丟棄，以排除 TCP 慢啟動階段。
4. **統計**：
   - **P50（中位數）** — 報告的主要速度；對偶發的下降或尖峰具有魯棒性。
   - **P90（第 90 百分位數）** — 峰值持續速度；反映連結能維持的最佳吞吐量。
5. **備用方案**：如果收集的檢查點不足（非常短的測試），算法回退到整體字節除以時間的平均值。

#### 為什麼使用滑動窗口？

| | 舊算法 | 新算法 |
|---|---|---|
| 採樣 | 每個回調的瞬時速率 | 累積字節檢查點 |
| 窗口 | 無 | 500 毫秒重疊窗口 |
| 預熱 | 前 20% 的樣本（基於計數） | 前 1500 毫秒（基於時間） |
| 異常值處理 | IQR 過濾器 | 自然 — 窗口平滑尖峰 |
| 輸出 | 單一平均速度 | P50 + P90 |

滑動窗口比每個回調增量速率對事件迴圈抖動的敏感度更低，中位數 (P50) 本質上對異常值具有魯棒性，無需顯式過濾。

### CI / CD

`.github/workflows/` 下提供了兩個手動觸發的 GitHub Actions 工作流程：

| 工作流程 | 檔案 | 說明 |
|---|---|---|
| **構建和發佈** | `build-release.yml` | 構建 APK (Android)、IPA (iOS, 無代碼簽署)、`.zip` (macOS & Windows)、`.tar.gz` (Linux)，然後建立帶有所有構件的 GitHub Release。版本標籤從 `pubspec.yaml` 自動讀取，或您可以在調度時覆蓋它。 |
| **清理舊運行** | `cleanup-runs.yml` | 刪除所有工作流程運行歷史記錄，每個工作流程僅保留最近 N 次運行（預設 1）。在調度時配置 N。 |

兩個工作流程都通過 **Actions → Run workflow** 觸發，絕不會自動運行。

> **iOS 注意**：iOS 構建使用 `--no-codesign`。生成的 `.ipa` 可以側載，但未經有效的配置檔案和憑證無法提交到 App Store。

### 開始使用

#### 先決條件

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio / Xcode（適用於行動平台）

#### 安裝

1. 克隆儲存庫：
   ```bash
   git clone https://github.com/ian20040409/LocalNetSpeed-flutter.git
   ```
2. 安裝依賴項：
   ```bash
   flutter pub get
   ```
3. 運行應用程式：
   ```bash
   flutter run
   ```

### 使用方法

1. **啟動伺服器**：在一個設備上，選擇「伺服器」模式並按一下「啟動伺服器」。記下顯示的本地 IP。
2. **啟動用戶端**：在第二個設備上，選擇「用戶端」模式，輸入伺服器的 IP 位址，並配置測試：
   - **大小限制**（預設）：輸入 MB 中的數據大小並按一下「開始測試」。
   - **時間限制**：啟用「時間導向測試」開關，輸入秒數，然後按一下「開始測試」。
3. **評估模式**：應用程式會自動偵測 WiFi 或有線連線並選擇適當的評估模式。您可以在「Gigabit 有線」和「WiFi 區網」之間手動切換，或按一下「自動」重新啟用自動偵測。
4. **查看結果**：結果對話方塊在計量表上顯示 P50 速度，以及 P90 徽章和總傳輸數據及時間。日誌視圖根據所選模式顯示完整的 P50/P90 詳細資訊和評估。

### 相關項目

- [LocalNetSpeed-swift](https://github.com/ian20040409/LocalNetSpeed-swift)：適合 Apple 生態系統愛好者的原始 Swift 實現。

### 許可證

此項目在 MIT 許可證下獲得許可 - 詳見 [LICENSE](LICENSE) 檔案。
