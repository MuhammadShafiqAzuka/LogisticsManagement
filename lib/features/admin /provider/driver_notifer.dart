import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/driver_repository.dart';
import '../model/driver.dart';
import '../model/job.dart';

class DriverNotifier extends StateNotifier<AsyncValue<List<Driver>>> {
  final DriverRepository repository;
  late final StreamSubscription _sub;

  DriverNotifier(this.repository) : super(const AsyncValue.loading()) {
    // 🟢 This is admin-only!
    _sub = repository.watchAllDrivers().listen(
          (drivers) {
        state = AsyncValue.data(drivers);
      },
      onError: (e, st) {
        state = AsyncValue.error(e, st);
      },
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> addDriver(Driver driver) async =>
      repository.addDriver(driver);

  Future<void> updateDriver(Driver updated) async =>
      repository.updateDriver(updated);

  Future<void> deleteDriver(String id) async =>
      repository.deleteDriver(id);

  Stream<Driver> watchCurrentDriver(String uid) =>
      repository.watchCurrentDriver(uid);

  Stream<LatLngPoint?> watchDriverLocation(String driverId) =>
      repository.watchDriverLocation(driverId);

  Stream<Map<String, LatLngPoint>> watchAllDriversLocations() =>
      repository.watchAllDriversLocations();
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