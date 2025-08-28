import 'dart:io';
import 'dart:typed_data';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/const.dart';
import '../model/driver_job_status.dart';

class JobStatusNotifier extends StateNotifier<Map<String, JobStatusUpdate>> {
  JobStatusNotifier() : super({});

  final CollectionReference jobsCollection =
  FirebaseFirestore.instance.collection('jobs');
  final storage = StorageService();

  /// Update job status in Firestore
  Future<void> updateStatus(
      String jobId,
      String status, {
        String? proofPath,
        Uint8List? signatureBytes,
        String? reason,
      }) async {
    try {
      String? photoUrl;
      String? signatureUrl;

      // Upload photo if provided
      if (proofPath != null) {
        photoUrl = await storage.uploadFileToStorage(jobId, File(proofPath), "proofPhoto");
      }

      // Upload signature if provided
      if (signatureBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${jobId}_signature.png');
        await tempFile.writeAsBytes(signatureBytes);
        signatureUrl = await storage.uploadFileToStorage(jobId, tempFile, "proofSignature");
      }

      // Build proof payload
      final proofData = <String, dynamic>{};
      if (status == "finished") {
        if (photoUrl != null) proofData["proofPhoto"] = photoUrl;
        if (signatureUrl != null) proofData["proofSignature"] = signatureUrl;
      } else if (status == "pending" || status == "returned") {
        if (reason != null) proofData["proofReason"] = reason;
        if (photoUrl != null) proofData["proofPhoto"] = photoUrl;
      }

      // Update Firestore
      await jobsCollection.doc(jobId).update({
        "status": status,
        "updatedAt": FieldValue.serverTimestamp(),
        if (proofData.isNotEmpty) "proof": proofData,
      });

      // Update local state
      state = {
        ...state,
        jobId: JobStatusUpdate(
          status: status,
          proofPhotoUrl: photoUrl,
          proofSignatureUrl: signatureUrl,
          reason: reason,
        ),
      };
    } catch (e) {
      print("❌ Error updating job status: $e");
    }
  }

  JobStatusUpdate? getStatus(String jobId) => state[jobId];
}

final jobStatusProvider =
StateNotifierProvider<JobStatusNotifier, Map<String, JobStatusUpdate>>(
        (ref) => JobStatusNotifier());