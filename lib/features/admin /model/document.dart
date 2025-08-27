class Document {
  final String licencePhoto;
  final String icPhoto;

  Document({
    required this.licencePhoto,
    required this.icPhoto,
  });

  /// Create a Document from a Map (Firestore)
  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      licencePhoto: map['licencePhoto'] ?? '',
      icPhoto: map['icPhoto'] ?? '',
    );
  }

  /// Convert Document to Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'licencePhoto': licencePhoto,
      'icPhoto': icPhoto,
    };
  }
}