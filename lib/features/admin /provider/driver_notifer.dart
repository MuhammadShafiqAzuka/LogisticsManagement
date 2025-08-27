import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/driver_repository.dart';
import '../model/driver.dart';
import '../model/job.dart';

class DriverNotifier extends StateNotifier<AsyncValue<List<Driver>>> {
  final DriverRepository repository;
  late final StreamSubscription _sub;

  DriverNotifier(this.repository) : super(const AsyncValue.loading()) {
    // Listen for real-time driver updates from Firestore
    _sub = repository.watchAllDrivers().listen(
          (drivers) => state = AsyncValue.data(drivers),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> addDriver(Driver driver) async {
    await repository.addDriver(driver);
  }

  Future<void> updateDriver(Driver updated) async {
    await repository.updateDriver(updated);
  }

  Future<void> deleteDriver(String id) async {
    await repository.deleteDriver(id);
  }

  /// RTDB: stream single driver's location
  Stream<LatLngPoint?> watchDriverLocation(String driverId) {
    return repository.watchDriverLocation(driverId);
  }

  /// RTDB: stream all drivers' locations
  Stream<Map<String, LatLngPoint>> watchAllDriversLocations() {
    return repository.watchAllDriversLocations();
  }

  /// ✅ Assign role in Firestore
  Future<void> assignRole({required String uid, required String role}) async {
    final usersRef = FirebaseFirestore.instance.collection("users").doc(uid);

    await usersRef.set(
      {"role": role},
      SetOptions(merge: true), // merge so we don’t overwrite existing data
    );
  }
}

// Providers
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

final driverNotifierProvider =
StateNotifierProvider<DriverNotifier, AsyncValue<List<Driver>>>((ref) {
  final repo = ref.read(driverRepositoryProvider);
  return DriverNotifier(repo);
});