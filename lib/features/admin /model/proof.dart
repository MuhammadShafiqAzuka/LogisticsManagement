class Proof {
  final String? proofPhoto;
  final String? proofSignature;
  final String? proofReason;

  Proof({
    this.proofPhoto,
    this.proofSignature,
    this.proofReason,
  });

  Map<String, dynamic> toMap() {
    return {
      "proofPhoto": proofPhoto,
      "proofSignature": proofSignature,
      "proofReason": proofReason,
    };
  }

  factory Proof.fromMap(Map<String, dynamic> map) {
    return Proof(
      proofPhoto: map["proofPhoto"],
      proofSignature: map["proofSignature"],
      proofReason: map["proofReason"],
    );
  }
}