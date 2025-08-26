import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../firebase_options.dart';

Future<void> initializeService(String driverId) async {
  final service = FlutterBackgroundService();

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
  service.invoke("setDriverId", {"driverId": driverId});
}

/// Runs in background isolate
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Initialize Firebase for this isolate
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase init error in background isolate: $e');
  }

  String? driverId;
  final db = FirebaseDatabase.instance.ref();

  // Listen to driverId sent from main isolate
  if (service is AndroidServiceInstance) {
    service.on("setDriverId").listen((event) {
      driverId = event?["driverId"];
    });
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) => service.stopSelf());

  // Start a single position stream with distanceFilter
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
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

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}