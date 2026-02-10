# LocalNetSpeed-flutter

A high-performance local network speed testing tool built with Flutter. This application allows you to measure the data transfer rate between two devices on the same local network using a Client-Server architecture.

[![Related Project](https://img.shields.io/badge/Related-LocalNetSpeed--swift-orange?style=flat-square&logo=swift)](https://github.com/ian20040409/LocalNetSpeed-swift)

## Features

- **Cross-Platform Support**: Measure speeds between Android, iOS, macOS, Windows, and Linux.
- **Client/Server Modes**: 
  - **Server Mode**: Host a listener on your device to receive data.
  - **Client Mode**: Connect to a server IP to start the throughput test.
- **Material You Support**: Dynamic color theming on Android 12+.
- **Real-time Metrics**: Live speed gauge and progress tracking.
- **Gigabit Evaluation**: Identifies if your network environment supports Gigabit speeds.

## Speed Calculation Algorithm

This application utilizes a robust **Sequential Trimmed Mean** algorithm designed specifically for high-bandwidth local networks (LAN). This ensures accurate and stable results by effectively filtering out TCP slow-start phases and OS buffer spikes:

1.  **Sampling**: Instantaneous speed samples are collected periodically (every ~100ms) throughout the duration of the test.
2.  **Sequential Warm-up (Time-Domain)**:
    *   The first **20%** of samples are discarded to ignore the "TCP Slow Start" phase, ensuring the metric reflects the network's steady-state capacity rather than its ramp-up curve.
3.  **Stability Trimming (Value-Domain)**:
    *   **Top 10% Discarded**: Filters out "Buffer Bloat" spikes where OS buffering causes speed readings to briefly exceed physical link capacity.
    *   **Bottom 5% Discarded**: Filters out minor system jitter and noise during the steady state.
4.  **Averaging**: The final result is derived from the average of the remaining steady, clean samples.

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
2. **Start the Client**: On the second device, select "Client" mode, enter the Server's IP address, and click "Start Test".
3. **View Results**: The app will display the average speed, latency, and a gigabit compatibility evaluation.

## Related Projects

- [LocalNetSpeed-swift](https://github.com/ian20040409/LocalNetSpeed-swift): The original Swift implementation for Apple ecosystem enthusiasts.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.