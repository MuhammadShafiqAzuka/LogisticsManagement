class Document {
  final String? licencePhoto;
  final String? icPhoto;

  Document({this.licencePhoto, this.icPhoto});

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      licencePhoto: map['licencePhoto'] ?? '',
      icPhoto: map['icPhoto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (licencePhoto != null) map['licencePhoto'] = licencePhoto;
    if (icPhoto != null) map['icPhoto'] = icPhoto;
    return map;
  }
}