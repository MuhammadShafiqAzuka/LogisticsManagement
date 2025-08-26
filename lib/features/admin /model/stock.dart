class Stock {
  final String id;
  final String name;
  final String? details;

    Stock({required this.id, required this.name, this.details});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "details": details,
    };
  }

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      id: map["id"],
      name: map["name"],
      details: map["details"],
    );
  }
}