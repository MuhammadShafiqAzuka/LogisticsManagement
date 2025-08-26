import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../driver/providers/driver_job_provider.dart';
import '../data/job_repository.dart';
import '../model/job.dart';

class JobNotifier extends StateNotifier<List<Job>> {
  final JobRepository _repo;
  late final StreamSubscription _sub;

  JobNotifier(this._repo) : super([]) {
    _init();
  }

  void _init() {
    _sub = _repo.watchAllJobs().listen((jobs) {
      state = jobs;
    });
  }

  Future<void> addJobs(List<Job> jobs) async {
    for (final job in jobs) {
      await _repo.createJob(job);
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