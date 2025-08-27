import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

Future<void> initializeService(String driverId) async {
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();

  if (isRunning) {
    // Service exists, just update driverId
    await Future.delayed(const Duration(seconds: 1));
    service.invoke("setDriverId", {"driverId": driverId});
    service.invoke("setAsForeground");
  } else {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(),
    );

    await service.startService();
    await Future.delayed(const Duration(seconds: 1));
    service.invoke("setDriverId", {"driverId": driverId});
    service.invoke("setAsForeground");
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Initialize Firebase in isolate
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase init error: $e");
  }

  String? driverId;
  final db = FirebaseDatabase.instance.ref();

  // Listen for driverId
  service.on("setDriverId").listen((event) {
    driverId = event?["driverId"];
    print("DriverId set in isolate: $driverId");
  });

  // Stop service listener
  service.on("stopService").listen((event) => service.stopSelf());

  // Start location stream
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    ),
  ).listen((pos) {
    if (driverId != null) {
      db.child("drivers/$driverId/location").set({
        "lat": double.parse(pos.latitude.toStringAsFixed(5)),
        "lng": double.parse(pos.longitude.toStringAsFixed(5)),
        "timestamp": ServerValue.timestamp,
      });
    }
  });
}