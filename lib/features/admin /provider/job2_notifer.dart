import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../driver/providers/driver_job_provider.dart';
import '../data/job2_repository.dart';
import '../model/job.dart';

final job2NotifierProvider = StateNotifierProvider<Job2Notifier, List<Job2>>((ref) {
  final repo = ref.watch(job2RepositoryProvider);
  return Job2Notifier(repo);
});

class Job2Notifier extends StateNotifier<List<Job2>> {
  final Job2Repository _repo;
  late final StreamSubscription _sub;

  Job2Notifier(this._repo) : super([]) {
    _init();
  }

  void _init() {
    _sub = _repo.watchAllJobs().listen((jobs) {
      state = jobs;
    });
  }

  Future<void> addJobs(List<Job2> jobs) async {
    for (final job in jobs) {
      await _repo.createJob(job);
      print("Job ${job.id} created and notification sent to driver ${job.driverId}");
    }
  }

  Future<void> updateStatus(String jobId, String status) async {
    await _repo.updateJobStatus(jobId, status);
  }

  Future<void> removeJob(String jobId) async {
    await _repo.deleteJob(jobId);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}