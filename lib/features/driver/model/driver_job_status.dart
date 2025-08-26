import 'dart:typed_data';

class JobStatusUpdate {
  final String status;
  final String? proofPath;
  final Uint8List? signatureBytes;
  final String? reason;

  JobStatusUpdate({
    required this.status,
    this.proofPath,
    this.signatureBytes,
    this.reason,
  });
}