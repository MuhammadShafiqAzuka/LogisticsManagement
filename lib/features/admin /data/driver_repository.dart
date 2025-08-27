import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../model/driver.dart';
import '../model/job.dart';

class DriverRepository {
  // Firestore collection for driver profile
  final CollectionReference driversCollection =
  FirebaseFirestore.instance.collection('drivers');

  // Realtime Database reference for live locations
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Firestore: stream all drivers in real-time for admin
  Stream<List<Driver>> watchAllDrivers() {
    return driversCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Driver.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          // fallback safe empty driver if bad data
          return Driver.empty(id: doc.id);
        }
      }).toList();
    });
  }

  /// Firestore: add a driver
  Future<void> addDriver(Driver driver) async {
    await driversCollection.doc(driver.id).set(driver.toMap());
  }

  /// Firestore: update driver
  Future<void> updateDriver(Driver updated) async {
    await driversCollection.doc(updated.id).update(updated.toMap());
  }

  /// Firestore: delete driver
  Future<void> deleteDriver(String id) async {
    await driversCollection.doc(id).delete();
    // Optionally, remove location from RTDB
    await _database.child("drivers/$id/location").remove();
  }

  /// RTDB: stream single driver's location in real-time
  Stream<LatLngPoint?> watchDriverLocation(String driverId) {
    return _database.child("drivers/$driverId/location").onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      return LatLngPoint(
        latitude: (data['lat'] as num).toDouble(),
        longitude: (data['lng'] as num).toDouble(),
      );
    });
  }

  /// RTDB: stream all drivers' locations in real-time
  Stream<Map<String, LatLngPoint>> watchAllDriversLocations() {
    return _database.child("drivers").onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};

      final Map<String, LatLngPoint> locations = {};

      if (data is Map) {
        data.forEach((key, value) {
          final driverData = value as Map?;
          final loc = driverData?['location'] as Map?;
          if (loc == null) return;
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          locations[key.toString()] =
              LatLngPoint(latitude: lat, longitude: lng);
        });
      }

      return locations;
    });
  }
}