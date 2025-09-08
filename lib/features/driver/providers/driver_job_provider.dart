import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../admin /data/job2_repository.dart';
import '../../admin /model/job.dart';
import '../../admin /data/driver_repository.dart';
import 'driver_job_status_notifer.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});


final job2RepositoryProvider = Provider<Job2Repository>((ref) {
  return Job2Repository();
});

/// ✅ All driver jobs stream
final driverJobsStreamProvider =
StreamProvider.family<List<Job2>, String>((ref, driverId) {
  return ref.watch(job2RepositoryProvider).watchActiveDriverJobs(driverId);
});

/// ✅ Filtered jobs by status
final driverJobsByStatusProvider =
Provider.family<List<Job2>, (String driverId, String status)>((ref, input) {
  final (driverId, status) = input;
  final jobsAsync = ref.watch(driverJobsStreamProvider(driverId));
  final updates = ref.watch(jobStatusProvider);

  return jobsAsync.maybeWhen(
    data: (jobs) {
      return jobs.where((job) {
        final update = updates[job.id];
        final effectiveStatus = update?.status ?? job.status;
        return effectiveStatus == status;
      }).toList();
    },
    orElse: () => [],
  );
});

/// Convenience shortcuts
final activeJobsProvider =
Provider.family<List<Job2>, String>((ref, driverId) =>
    ref.watch(driverJobsByStatusProvider((driverId, "active"))));

final finishedJobsProvider =
Provider.family<List<Job2>, String>((ref, driverId) =>
    ref.watch(driverJobsByStatusProvider((driverId, "finished"))));

final pendingJobsProvider =
Provider.family<List<Job2>, String>((ref, driverId) =>
    ref.watch(driverJobsByStatusProvider((driverId, "pending"))));

final returnedJobsProvider =
Provider.family<List<Job2>, String>((ref, driverId) =>
    ref.watch(driverJobsByStatusProvider((driverId, "returned"))));


