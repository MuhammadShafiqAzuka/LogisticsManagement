import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/admin /model/job.dart';
import 'package:geolocator/geolocator.dart';


const String apiKey = "AIzaSyA5d1fDP_IpTBJtbzMPKfWNup9SxcegOQY";
enum CompleteMode { finished, pending, returned }

Future<bool> checkAndRequestPermissions({required bool isDriver}) async {
  try {
    if (isDriver) {
      // Only location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }
    else {
      // Only storage/photos
      bool storageGranted = false;
      if (Platform.isAndroid) {
        var androidInfo = await DeviceInfoPlugin().androidInfo;
        int sdkInt = androidInfo.version.sdkInt;
        if (sdkInt >= 33) {
          var status = await Permission.photos.request();
          storageGranted = status.isGranted;
        } else {
          var status = await Permission.storage.request();
          storageGranted = status.isGranted;
        }
      } else if (Platform.isIOS) {
        var status = await Permission.photos.request();
        storageGranted = status.isGranted;
      }
      return storageGranted;
    }
  } catch (e) {
    print('Error requesting permissions: $e');
    return false;
  }
}

Future<void> confirmAndLaunch(BuildContext context, String title, String message, Uri url) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  if (result == true) {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

void openGoogleMaps(BuildContext context, double lat, double lng) {
  final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");
  confirmAndLaunch(
    context,
    "Open Google Maps",
    "This will open Google Maps in your default browser or app. Continue?",
    url,
  );
}

void openWaze(BuildContext context, double lat, double lng) {
  final url = Uri.parse("https://waze.com/ul?ll=$lat,$lng&navigate=yes");
  confirmAndLaunch(
    context,
    "Open Waze",
    "This will open Waze in your default browser or app. Continue?",
    url,
  );
}

LatLngPoint getRandomPointBetween(LatLngPoint start, LatLngPoint end) {
  final random = Random();

  // Generate a random factor between 0.1 and 0.9
  final t = 0.1 + random.nextDouble() * 0.8;

  final lat = start.latitude + (end.latitude - start.latitude) * t;
  final lng = start.longitude + (end.longitude - start.longitude) * t;

  return LatLngPoint(latitude: lat, longitude: lng);
}

Map<String, dynamic> statusStyle(String status) {
  switch (status) {
    case 'active':
      return {'bg': Colors.orange[100], 'text': Colors.orange[800]};
    case 'pending':
      return {'bg': Colors.blue[100], 'text': Colors.blue[800]};
    case 'returned':
      return {'bg': Colors.red[100], 'text': Colors.red[800]};
    case 'finished':
      return {'bg': Colors.green[100], 'text': Colors.green[800]};
    default:
      return {'bg': Colors.grey[200], 'text': Colors.grey[800]};
  }
}

DateTime parseExcelDate(String? raw) {
  if (raw == null || raw.isEmpty) return DateTime.now();

  try {
    // First try standard ISO (yyyy-MM-dd)
    return DateTime.parse(raw);
  } catch (_) {
    try {
      // Handle dd/MM/yyyy
      final parts = raw.split(RegExp(r'[-/ ]'));
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
  }

  // fallback if all fails
  return DateTime.now();
}