import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

class LocalIPHelper {
  static Future<String> getLocalIPAddress() async {
    if (kIsWeb) {
      return "Web Not Supported";
    }
    try {
      // Try network_info_plus first for WiFi IP (most common use case)
      final info = NetworkInfo();
      var wifiIP = await info.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty && wifiIP != "0.0.0.0") {
        return wifiIP;
      }

      // Fallback to dart:io NetworkInterface
      // This helps with wired connections or when WiFi info is restricted
      for (var interface in await NetworkInterface.list()) {
        // Filter out loopback and link-local if possible, though list() usually does real interfaces
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
             // Prefer 192.168.x.x or 10.x.x.x or 172.x.x.x
             if (addr.address.startsWith("192.168.") || 
                 addr.address.startsWith("10.") ||
                 (addr.address.startsWith("172.") && _isClassB(addr.address))) {
               return addr.address;
             }
          }
        }
      }
      
      // If no private IP found, just take the first IPv4 non-loopback
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }

    } catch (e) {
      print("Error getting IP: $e");
    }
    return "無法取得";
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
