import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/const.dart';
import '../model/document.dart';
import '../model/driver.dart';
import '../model/job.dart';
import '../model/vehicle.dart';
import '../model/stock.dart';

class DriverRepository {
  static final pickup = LatLngPoint(latitude: 3.1390, longitude: 101.6869);
  static final dropoff = LatLngPoint(latitude: 3.1073, longitude: 101.6067);
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final List<Driver> _mockDrivers = [
    Driver(
      id: '1',
      icNumber: '900101-14-5678',
      email: 'driver1@test.com',
      passwordHash: 'pw1',
      phoneNumber: '012-3456789',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'KEX6191',
        type: 'Dry',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      previousStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '2',
      icNumber: '920202-10-9876',
      email: 'driver2@test.com',
      passwordHash: 'pw2',
      phoneNumber: '013-9876543',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'PEF777Q',
        type: 'Frozen',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      previousStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '3',
      icNumber: '910303-11-1122',
      email: 'driver3@test.com',
      passwordHash: 'pw3',
      phoneNumber: '014-1122334',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'ASD1234',
        type: 'Cold',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      previousStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '4',
      icNumber: '940404-09-3344',
      email: 'driver4@test.com',
      passwordHash: 'pw4',
      phoneNumber: '015-3344556',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'FDG3214',
        type: 'Cold',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '4', name: 'Others (Medicines)'),
      ],
      previousStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '5',
      icNumber: '880505-10-5566',
      email: 'driver5@test.com',
      passwordHash: 'pw5',
      phoneNumber: '016-5566778',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Van',
        registrationNumber: 'WER1234',
        type: 'Dry',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Stationery)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '6',
      icNumber: '870606-08-7788',
      email: 'driver6@test.com',
      passwordHash: 'pw6',
      phoneNumber: '017-7788990',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'QWE5678',
        type: 'Frozen',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      previousStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '7',
      icNumber: '950707-12-8899',
      email: 'driver7@test.com',
      passwordHash: 'pw7',
      phoneNumber: '018-8899001',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Van',
        registrationNumber: 'TYU8765',
        type: 'Cold',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Beverages)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '8',
      icNumber: '960808-14-9900',
      email: 'driver8@test.com',
      passwordHash: 'pw8',
      phoneNumber: '019-9900112',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Truck',
        registrationNumber: 'ZXC4321',
        type: 'Dry',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '4', name: 'Others (Chemicals)'),
      ],
      previousStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),

    Driver(
      id: '9',
      icNumber: '970909-15-1122',
      email: 'driver9@test.com',
      passwordHash: 'pw9',
      phoneNumber: '011-2233445',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'BNM9087',
        type: 'Frozen',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Seafood)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '10',
      icNumber: '980101-13-2233',
      email: 'driver10@test.com',
      passwordHash: 'pw10',
      phoneNumber: '012-3344556',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Van',
        registrationNumber: 'HJK7654',
        type: 'Cold',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      previousStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '11',
      icNumber: '990202-11-3344',
      email: 'driver11@test.com',
      passwordHash: 'pw11',
      phoneNumber: '013-4455667',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Truck',
        registrationNumber: 'PLK1122',
        type: 'Dry',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Furniture)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '12',
      icNumber: '000303-12-4455',
      email: 'driver12@test.com',
      passwordHash: 'pw12',
      phoneNumber: '014-5566778',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Van',
        registrationNumber: 'MNB3344',
        type: 'Cold',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      previousStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '13',
      icNumber: '010404-13-5566',
      email: 'driver13@test.com',
      passwordHash: 'pw13',
      phoneNumber: '015-6677889',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'VFR5566',
        type: 'Frozen',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Frozen Meat)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '14',
      icNumber: '020505-14-6677',
      email: 'driver14@test.com',
      passwordHash: 'pw14',
      phoneNumber: '016-7788990',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Van',
        registrationNumber: 'CDE7788',
        type: 'Dry',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      previousStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '15',
      icNumber: '030606-15-7788',
      email: 'driver15@test.com',
      passwordHash: 'pw15',
      phoneNumber: '017-8899001',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Truck',
        registrationNumber: 'RTY8899',
        type: 'Frozen',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Ice Cream)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '16',
      icNumber: '040707-16-8899',
      email: 'driver16@test.com',
      passwordHash: 'pw16',
      phoneNumber: '018-9900112',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Lorry',
        registrationNumber: 'GHJ9900',
        type: 'Cold',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      previousStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '17',
      icNumber: '050808-17-9900',
      email: 'driver17@test.com',
      passwordHash: 'pw17',
      phoneNumber: '019-1011121',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Van',
        registrationNumber: 'JKL2233',
        type: 'Dry',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Books)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '18',
      icNumber: '060909-18-1122',
      email: 'driver18@test.com',
      passwordHash: 'pw18',
      phoneNumber: '011-1213141',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Truck',
        registrationNumber: 'LMN3344',
        type: 'Frozen',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '1', name: 'Freezer Temperature'),
      ],
      previousStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '19',
      icNumber: '071010-19-2233',
      email: 'driver19@test.com',
      passwordHash: 'pw19',
      phoneNumber: '012-1314151',
      profilePhoto: 'assets/driver1.jpg',
      vehicle: Vehicle(
        name: 'Van',
        registrationNumber: 'OPQ4455',
        type: 'Cold',
      ),
      document: Document(
        licencePhoto: 'assets/licence2.jpg',
        icPhoto: 'assets/licence2.jpg',
      ),
      activeStocks: [
        Stock(id: '2', name: 'Cold Temperature'),
      ],
      previousStocks: [
        Stock(id: '4', name: 'Others (Dairy)'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),
    Driver(
      id: '20',
      icNumber: '081111-20-3344',
      email: 'driver20@test.com',
      passwordHash: 'pw20',
      phoneNumber: '013-1415161',
      profilePhoto: 'assets/driver2.jpg',
      vehicle: Vehicle(
        name: 'Truck',
        registrationNumber: 'RST5566',
        type: 'Dry',
      ),
      document: Document(
        licencePhoto: 'assets/licence1.jpg',
        icPhoto: 'assets/licence1.jpg',
      ),
      activeStocks: [
        Stock(id: '4', name: 'Others (Clothing)'),
      ],
      previousStocks: [
        Stock(id: '3', name: 'Room Temperature'),
      ],
      lastLocation: LatLngPoint(latitude: 0, longitude: 0),
    ),

  ];
  ///get all drive for admin
  Future<List<Driver>> getAllDrivers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockDrivers;
  }

  ///add driver for admin
  Future<void> addDriver(Driver driver) async {
    _mockDrivers.add(driver);
  }

  ///update driver for admin
  Future<void> updateDriver(Driver updated) async {
    final index = _mockDrivers.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      _mockDrivers[index] = updated;
    }
  }

  ///delete driver for admin
  Future<void> deleteDriver(String id) async {
    _mockDrivers.removeWhere((d) => d.id == id);
  }

  ///get last location of driver for driver and admin
  Stream<LatLngPoint?> watchDriverLocation(String driverId) {
    return _database.child("drivers/$driverId/location").onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      return LatLngPoint(
        latitude: (data['lat'] as num).toDouble(),
        longitude: (data['lng'] as num).toDouble(),
      );
    });
  }

  /// Stream of all drivers' locations
  Stream<Map<String, LatLngPoint>> watchAllDriversLocations() {
    return _database.child("drivers").onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null) return {};

      final Map<String, LatLngPoint> locations = {};

      if (data is List) {
        // When drivers are stored as a list
        for (int i = 0; i < data.length; i++) {
          final driverData = data[i] as Map?;
          if (driverData == null) continue;

          final loc = driverData['location'] as Map?;
          if (loc == null) continue;

          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();

          locations[i.toString()] = LatLngPoint(latitude: lat, longitude: lng);
        }
      } else if (data is Map) {
        // When drivers are stored as a map
        data.forEach((key, value) {
          final driverData = value as Map?;
          if (driverData == null) return;

          final loc = driverData['location'] as Map?;
          if (loc == null) return;

          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();

          locations[key.toString()] = LatLngPoint(latitude: lat, longitude: lng);
        });
      }

      return locations;
    });
  }
}