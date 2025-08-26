import 'package:logistic_management/features/admin%20/model/stock.dart';
import 'job.dart';
import 'vehicle.dart';
import 'document.dart';

class Driver {
  final String id;
  final String icNumber;
  final String email;
  final String passwordHash;
  final String phoneNumber;
  final String profilePhoto;
  final Vehicle vehicle;
  final Document document;
  List<Stock> activeStocks;
  List<Stock> previousStocks;
  final LatLngPoint? lastLocation;

  Driver({
    required this.id,
    required this.icNumber,
    required this.email,
    required this.passwordHash,
    required this.phoneNumber,
    required this.profilePhoto,
    required this.vehicle,
    required this.document,
    required this.activeStocks,
    required this.previousStocks,
    this.lastLocation,
  });

  /// Named constructor for an empty/default driver
  factory Driver.empty() {
    return Driver(
      id: 'unknown',
      icNumber: '',
      email: 'Unknown',
      passwordHash: '',
      phoneNumber: '',
      profilePhoto: '',
      vehicle: Vehicle(name: 'Unknown Lorry', registrationNumber: '', type: ''),
      document: Document(icPhoto: '', licencePhoto: ''),
      activeStocks: [],
      previousStocks: [],
      lastLocation: null,
    );
  }
}