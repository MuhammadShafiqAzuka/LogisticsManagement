class JobStatusUpdate {
  final String status;
  final String? proofPhotoUrl;
  final String? proofSignatureUrl;
  final String? reason;

  JobStatusUpdate({
    required this.status,
    this.proofPhotoUrl,
    this.proofSignatureUrl,
    this.reason,
  });

  JobStatusUpdate copyWith({
    String? status,
    String? proofPhotoUrl,
    String? proofSignatureUrl,
    String? reason,
  }) {
    return JobStatusUpdate(
      status: status ?? this.status,
      proofPhotoUrl: proofPhotoUrl ?? this.proofPhotoUrl,
      proofSignatureUrl: proofSignatureUrl ?? this.proofSignatureUrl,
      reason: reason ?? this.reason,
    );
  }
}