class Vehicle {
  final String name;
  final String registrationNumber;
  final String type;

  Vehicle({required this.name, required this.registrationNumber, required this.type});

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
    name: map['name'] ?? '',
    registrationNumber: map['registrationNumber'] ?? '',
    type: map['type'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'registrationNumber': registrationNumber,
    'type': type,
  };
}