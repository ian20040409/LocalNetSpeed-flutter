import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

enum ConnectionType {
  wifi,
  wired,
  unknown,
}

class NetworkDetectionResult {
  final String ip;
  final ConnectionType connectionType;

  NetworkDetectionResult({required this.ip, required this.connectionType});
}

class LocalIPHelper {
  static Future<String> getLocalIPAddress() async {
    final result = await detectNetwork();
    return result.ip;
  }

  static Future<NetworkDetectionResult> detectNetwork() async {
    if (kIsWeb) {
      return NetworkDetectionResult(ip: "Web Not Supported", connectionType: ConnectionType.unknown);
    }
    try {
      // Try network_info_plus first for WiFi IP (most common use case)
      final info = NetworkInfo();
      var wifiIP = await info.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty && wifiIP != "0.0.0.0") {
        return NetworkDetectionResult(ip: wifiIP, connectionType: ConnectionType.wifi);
      }

      // Fallback to dart:io NetworkInterface — likely wired connection
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
             if (addr.address.startsWith("192.168.") ||
                 addr.address.startsWith("10.") ||
                 (addr.address.startsWith("172.") && _isClassB(addr.address))) {
               return NetworkDetectionResult(ip: addr.address, connectionType: ConnectionType.wired);
             }
          }
        }
      }

      // If no private IP found, just take the first IPv4 non-loopback
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return NetworkDetectionResult(ip: addr.address, connectionType: ConnectionType.unknown);
          }
        }
      }

    } catch (e) {
      print("Error getting IP: $e");
    }
    return NetworkDetectionResult(ip: "無法取得", connectionType: ConnectionType.unknown);
  }

  static bool _isClassB(String ip) {
    try {
      final parts = ip.split('.');
      final second = int.parse(parts[1]);
      return second >= 16 && second <= 31;
    } catch (_) {
      return false;
    }
  }
}
