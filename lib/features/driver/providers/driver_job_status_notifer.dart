import 'dart:typed_data';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/driver_job_status.dart';

class JobStatusNotifier extends StateNotifier<Map<String, JobStatusUpdate>> {
  JobStatusNotifier() : super({});

  final CollectionReference jobsCollection =
  FirebaseFirestore.instance.collection('jobs');

  /// Update job status in Firestore
  Future<void> updateStatus(
      String jobId,
      String status, {
        String? proofPath,
        Uint8List? signatureBytes,
        String? reason,
      }) async {
    // 1️⃣ Update local state immediately
    state = {
      ...state,
      jobId: JobStatusUpdate(
        status: status,
        proofPath: proofPath,
        signatureBytes: signatureBytes,
        reason: reason,
      ),
    };

    // 2️⃣ Prepare proof data conditionally
    Map<String, dynamic> proofData = {};
    if (status == "finished") {
      proofData = {
        "proofPhoto": proofPath,
        "proofSignature": signatureBytes != null ? String.fromCharCodes(signatureBytes) : null,
      };
    } else if (status == "pending" || status == "returned") {
      proofData = {
        "proofReason": reason,
      };
    }

    // 3️⃣ Firestore update object
    final Map<String, dynamic> updateData = {
      "status": status,
      "updatedAt": FieldValue.serverTimestamp(),
      "proof": proofData,
    };

    // 4️⃣ Update Firestore
    await jobsCollection.doc(jobId).update(updateData);
  }

  JobStatusUpdate? getStatus(String jobId) => state[jobId];
}

final jobStatusProvider =
StateNotifierProvider<JobStatusNotifier, Map<String, JobStatusUpdate>>(
        (ref) => JobStatusNotifier());