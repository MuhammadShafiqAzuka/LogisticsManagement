import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../model/driver_job_status.dart';

import 'package:firebase_database/firebase_database.dart';

class JobStatusNotifier extends StateNotifier<Map<String, JobStatusUpdate>> {
  JobStatusNotifier() : super({});

  final _db = FirebaseDatabase.instance.ref(); // Realtime DB reference

  Future<void> updateStatus(
      String jobId,
      String status, {
        String? proofPath,
        Uint8List? signatureBytes,
        String? reason,
      }) async {
    // 1️⃣ Update local state (UI reacts instantly)
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
        "photo": proofPath,
        "signature": signatureBytes != null
            ? String.fromCharCodes(signatureBytes)
            : null,
      };
    } else if (status == "pending" || status == "returned") {
      proofData = {
        "reason": reason,
      };
    }

    // 3️⃣ Final update object
    final Map<String, dynamic> updateData = {
      "status": status,
      "updatedAt": DateTime.now().millisecondsSinceEpoch,
      "proof": {
        "proofPhoto": proofPath,
        "proofReason": reason,
        "proofSignature": signatureBytes != null ? "signature path" : null,
      }
    };

    // 4️⃣ Push update to Realtime DB
    await _db.child("jobs/$jobId").update(updateData);
  }

  JobStatusUpdate? getStatus(String jobId) => state[jobId];
}

final jobStatusProvider =
StateNotifierProvider<JobStatusNotifier, Map<String, JobStatusUpdate>>(
      (ref) => JobStatusNotifier(),
);