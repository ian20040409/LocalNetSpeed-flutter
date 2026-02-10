import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Net Speed',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SpeedTestPage(),
    );
  }
}

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  bool _isTesting = false;

  Future<void> _startTest() async {
    setState(() {
      _isTesting = true;
      _downloadSpeed = 0.0;
      _uploadSpeed = 0.0;
    });

    // Simulate network speed test
    const downloadUrl = 'https://speed.hetzner.de/100MB.bin';
    final startTime = DateTime.now();

    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        final bits = response.bodyBytes.length * 8;
        final speed = bits / (duration.inMicroseconds / 1000000) / 1000000; // Mbps

        setState(() {
          _downloadSpeed = speed;
        });
      }
    } catch (e) {
      // Handle error
    }


    // Simulate upload test
    await Future.delayed(const Duration(seconds: 2));
    final random = Random();
    final upload = random.nextDouble() * 50;

    setState(() {
      _uploadSpeed = upload;
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Net Speed'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Download Speed:', style: TextStyle(fontSize: 20)),
            Text(
              '${_downloadSpeed.toStringAsFixed(2)} Mbps',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Upload Speed:', style: TextStyle(fontSize: 20)),
            Text(
              '${_uploadSpeed.toStringAsFixed(2)} Mbps',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isTesting ? null : _startTest,
              child: _isTesting
                  ? const CircularProgressIndicator()
                  : const Text('Start Test'),
            ),
          ],
        ),
      ),
    );
  }
}
