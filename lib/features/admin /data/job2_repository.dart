import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/job.dart';

class Job2Repository {
  final CollectionReference jobsCollection = FirebaseFirestore.instance.collection('jobs');

  /// ✅ Stream all jobs in real-time
  Stream<List<Job2>> watchAllJobs() {
    return jobsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job2.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// ✅ Create a job
  Future<void> createJob(Job2 job) async {
    await jobsCollection.doc(job.id).set(job.toMap());
  }

  /// ✅ Update a job
  Future<void> updateJob(Job2 job) async {
    await jobsCollection.doc(job.id).update(job.toMap());
  }

  /// ✅ Update only the job status
  Future<void> updateJobStatus(String jobId, String newStatus) async {
    await jobsCollection.doc(jobId).update({
      'status': newStatus,
    });
  }

  /// ✅ Delete a job
  Future<void> deleteJob(String id) async {
    await jobsCollection.doc(id).delete();
  }

  /// ✅ Stream jobs for a specific driver
  Stream<List<Job2>> watchDriverJobs(String driverId) {
    return jobsCollection
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job2.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}