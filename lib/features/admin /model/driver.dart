import 'package:logistic_management/features/admin%20/model/stock.dart';
import 'vehicle.dart';
import 'document.dart';

class Driver {
  final String id;
  final String icNumber;
  final String email;
  final String passwordHash;
  final String phoneNumber;

  // Optional fields (filled later in profile)
  final String? profilePhoto;
  final Vehicle? vehicle;
  final Document? document;
  final List<Stock> activeStocks;
  final List<Stock> previousStocks;

  Driver({
    required this.id,
    required this.icNumber,
    required this.email,
    required this.passwordHash,
    required this.phoneNumber,
    this.profilePhoto,
    this.vehicle,
    this.document,
    this.activeStocks = const [],
    this.previousStocks = const [],
  });

  factory Driver.fromMap(Map<String, dynamic> map, String id) {
    return Driver(
      id: id,
      icNumber: map['icNumber'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePhoto: map['profilePhoto'],
      vehicle: map['vehicle'] != null ? Vehicle.fromMap(map['vehicle']) : null,
      document: map['document'] != null ? Document.fromMap(map['document']) : null,
      activeStocks: (map['activeStocks'] as List?)
          ?.map((s) => Stock.fromMap(s as Map<String, dynamic>))
          .toList() ??
          [],
      previousStocks: (map['previousStocks'] as List?)
          ?.map((s) => Stock.fromMap(s as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icNumber': icNumber,
      'email': email,
      'passwordHash': passwordHash,
      'phoneNumber': phoneNumber,
    };
  }

  /// Empty driver factory with safe defaults
  factory Driver.empty({String id = 'unknown'}) {
    return Driver(
      id: id,
      icNumber: '',
      email: '',
      passwordHash: '',
      phoneNumber: '',
      profilePhoto: null,
      vehicle: null,
      document: null,
      activeStocks: const [],
      previousStocks: const [],
    );
  }
}