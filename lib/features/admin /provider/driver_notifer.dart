import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/driver_repository.dart';
import '../model/driver.dart';
import '../model/job.dart';

class DriverNotifier extends StateNotifier<AsyncValue<List<Driver>>> {
  final DriverRepository repository;

  DriverNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadDrivers();
  }

  Future<void> loadDrivers() async {
    state = const AsyncValue.loading();
    try {
      final drivers = await repository.getAllDrivers();
      state = AsyncValue.data(drivers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDriver(Driver driver) async {
    state = const AsyncValue.loading();
    await repository.addDriver(driver);
    await loadDrivers();
  }

  Future<void> updateDriver(Driver updated) async {
    state = const AsyncValue.loading();
    await repository.updateDriver(updated);
    await loadDrivers();
  }

  Future<void> deleteDriver(String id) async {
    state = const AsyncValue.loading();
    await repository.deleteDriver(id);
    await loadDrivers();
  }

  Stream<LatLngPoint?> watchDriverLocation(String driverId) {
    return repository.watchDriverLocation(driverId);
  }

  Stream<Map<String, LatLngPoint>> watchAllDriversLocations() {
    return repository.watchAllDriversLocations();
  }
}

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

final driverNotifierProvider = StateNotifierProvider<DriverNotifier, AsyncValue<List<Driver>>>((ref) {
  final repo = ref.read(driverRepositoryProvider);
  return DriverNotifier(repo);
});