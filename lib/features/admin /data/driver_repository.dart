import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../model/driver.dart';
import '../model/job.dart';

class DriverRepository {
  final CollectionReference driversCollection =
  FirebaseFirestore.instance.collection('drivers');

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// 🛠️ For Admins: stream all drivers
  Stream<List<Driver>> watchAllDrivers() {
    return driversCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Driver.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          return Driver.empty(id: doc.id);
        }
      }).toList();
    });
  }

  /// 🚚 For Drivers: stream only current driver (by auth uid)
  Stream<Driver> watchCurrentDriver(String uid) {
    return driversCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return Driver.empty(id: uid);
      return Driver.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<void> addDriver(Driver driver) async {
    await driversCollection.doc(driver.id).set(driver.toMap());
  }

  Future<void> updateDriver(Driver updated) async {
    await driversCollection.doc(updated.id).update(updated.toMap());
  }

  Future<void> deleteDriver(String id) async {
    await driversCollection.doc(id).delete();
    await _database.child("drivers/$id/location").remove();
  }

  /// 🚚 For driver app: watch only one driver’s location
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

  /// 🛠️ For admin app: watch all driver locations
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