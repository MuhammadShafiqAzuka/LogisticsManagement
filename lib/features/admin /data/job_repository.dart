import 'package:firebase_database/firebase_database.dart';
import '../model/job.dart';

class JobRepository {
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  Stream<List<Job>> watchAllJobs() {
    return db
        .child("jobs")
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) {
        return Job.fromMap(Map<String, dynamic>.from(e.value), e.key);
      }).toList();
    });
  }

  Future<void> createJob(Job job) async {
    await db.child("jobs/${job.id}").set(job.toMap());
  }

  Future<void> updateJob(Job job) async {
    await db.child("jobs/${job.id}").update(job.toMap());
  }

  Future<void> updateJobStatus(String jobId, String newStatus) async {
    await db.child("jobs/$jobId").update({
      "status": newStatus,
    });
  }

  Future<void> deleteJob(String id) async {
    await db.child("jobs/$id").remove();
  }

  /// ✅ Realtime stream of jobs for a driver
  Stream<List<Job>> watchDriverJobs(String driverId) {
    return db
        .child("jobs")
        .orderByChild("driverId")
        .equalTo(driverId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      return data.entries.map((entry) {
        final jobData = Map<String, dynamic>.from(entry.value);
        return Job.fromMap(jobData, entry.key); // ✅ use fromMap
      }).toList();
    });
  }
}
