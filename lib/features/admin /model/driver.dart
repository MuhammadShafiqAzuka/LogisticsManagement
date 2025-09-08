import 'package:logistic_management/features/admin%20/model/stock.dart';
import 'vehicle.dart';
import 'document.dart';

class Driver {
  final String id;
  final String icNumber;
  final String email;
  final String phoneNumber;

  // Optional fields
  final String? passwordHash; // Only used in memory (e.g., registration), not Firestore
  final String? profilePhoto;
  final Vehicle? vehicle;
  final Document? document;
  final List<Stock> activeStocks;
  final List<Stock> previousStocks;

  Driver({
    required this.id,
    required this.icNumber,
    required this.email,
    this.passwordHash,
    required this.phoneNumber,
    this.profilePhoto,
    this.vehicle,
    this.document,
    this.activeStocks = const [],
    this.previousStocks = const [],
  });

  Driver copyWith({
    String? icNumber,
    String? email,
    String? phoneNumber,
    String? passwordHash,
    String? profilePhoto,
    Vehicle? vehicle,
    Document? document,
    List<Stock>? activeStocks,
    List<Stock>? previousStocks,
  }) {
    return Driver(
      id: id, // id stays the same
      icNumber: icNumber ?? this.icNumber,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passwordHash: passwordHash ?? this.passwordHash,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      vehicle: vehicle ?? this.vehicle,
      document: document ?? this.document,
      activeStocks: activeStocks ?? this.activeStocks,
      previousStocks: previousStocks ?? this.previousStocks,
    );
  }

  /// Create a Driver from Firestore data
  factory Driver.fromMap(Map<String, dynamic> map, String id) {
    return Driver(
      id: id,
      icNumber: map['icNumber'] ?? '',
      email: map['email'] ?? '',
      passwordHash: '', // never load from Firestore
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

  /// Convert Driver to Firestore map, only saving non-null optional fields
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'icNumber': icNumber,
      'email': email,
      'phoneNumber': phoneNumber,
    };

    if (profilePhoto != null) {
      data['profilePhoto'] = profilePhoto!; // safe cast
    }
    if (vehicle != null) {
      data['vehicle'] = vehicle!.toMap(); // Map<String, dynamic>
    }
    if (document != null) {
      data['document'] = document!.toMap(); // Map<String, dynamic>
    }
    if (activeStocks.isNotEmpty) {
      data['activeStocks'] = activeStocks.map((s) => s.toMap()).toList(); // List<Map<String, dynamic>>
    }
    if (previousStocks.isNotEmpty) {
      data['previousStocks'] = previousStocks.map((s) => s.toMap()).toList(); // List<Map<String, dynamic>>
    }

    return data;
  }

  /// Safe empty Driver
  factory Driver.empty({String id = ''}) {
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
