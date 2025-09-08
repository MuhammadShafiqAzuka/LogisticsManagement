import 'package:logistic_management/features/admin%20/model/proof.dart';
import '../../../core/constants/const.dart';

class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  factory LatLngPoint.fromMap(Map<String, dynamic> map) {
    return LatLngPoint(
      latitude: (map["latitude"] as num).toDouble(),
      longitude: (map["longitude"] as num).toDouble(),
    );
  }

  LatLngPoint copyWith({
    double? latitude,
    double? longitude,
  }) {
    return LatLngPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() => "LatLngPoint(lat: $latitude, lng: $longitude)";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLngPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

class Job2 {
  final String id; //
  final String driverId;
  final String orderType; //
  final DateTime dueDate; //
  final String pickupLocation; //
  final LatLngPoint pickupLatLng; //
  final String dropoffLocation; //
  final LatLngPoint dropoffLatLng; //
  final String address; //
  final String customerRef; //
  final String timeWindow; //
  final String orderAmount; //
  final String price; //
  final String stocks; //
  final String weight; //
  final String status;
  final DateTime date;
  final Proof? proof;

  Job2({
    required this.id,
    required this.driverId,
    required this.orderType,
    required this.dueDate,
    required this.pickupLocation,
    required this.pickupLatLng,
    required this.dropoffLocation,
    required this.dropoffLatLng,
    required this.address,
    required this.customerRef,
    required this.timeWindow,
    required this.orderAmount,
    required this.price,
    required this.stocks,
    required this.weight,
    required this.status,
    required this.date,
    this.proof,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "driverId": driverId,
      "orderType": orderType,
      "dueDate": dueDate.toIso8601String(),
      "pickupLocation": pickupLocation,
      "pickupLatLng": pickupLatLng.toMap(),
      "dropoffLocation": dropoffLocation,
      "dropoffLatLng": dropoffLatLng.toMap(),
      "address": address,
      "customerRef": customerRef,
      "timeWindow": timeWindow,
      "orderAmount": orderAmount,
      "price": price,
      "stocks": stocks,
      "weight": weight,
      "status": status,
      "date": date.toIso8601String(),
      "proof": proof?.toMap(),
    };
  }

  factory Job2.fromMap(Map<String, dynamic> map, String id) {
    return Job2(
      id: id,
      driverId: map["driverId"],
      orderType: map["orderType"],
      dueDate: DateTime.parse(map["dueDate"]),
      pickupLocation: map["pickupLocation"],
      pickupLatLng: LatLngPoint.fromMap(Map<String, dynamic>.from(map["pickupLatLng"])),
      dropoffLocation: map["dropoffLocation"],
      dropoffLatLng: LatLngPoint.fromMap(Map<String, dynamic>.from(map["dropoffLatLng"])),
      address: map["address"],
      customerRef: map["customerRef"],
      timeWindow: map["timeWindow"],
      orderAmount: map["orderAmount"],
      price: map["price"],
      stocks: map["stocks"],
      weight: map["weight"],
      status: map["status"],
      date: DateTime.parse(map["date"]),
      proof: map["proof"] != null ? Proof.fromMap(Map<String, dynamic>.from(map["proof"])) : null,
    );
  }

  factory Job2.fromExcelRow(Map<String, dynamic> row, String driverId) {
    return Job2(
      id: row["Order ID"].toString(),
      driverId: driverId,
      orderType: row["Order Type"].toString(),
      dueDate: parseExcelDate(row["Due Date"]?.toString()),
      pickupLocation: row["Location ID"].toString(),
      pickupLatLng: LatLngPoint(
        latitude: double.tryParse(row["Pickup Latitude"].toString()) ?? 0.0,
        longitude: double.tryParse(row["Pickup Longitude"].toString()) ?? 0.0,
      ),
      dropoffLocation: row["Drop Off Location"].toString(),
      dropoffLatLng: LatLngPoint(
        latitude: double.tryParse(row["Drop Off Latitude"].toString()) ?? 0.0,
        longitude: double.tryParse(row["Drop Off Longitude"].toString()) ?? 0.0,
      ),
      address: row["Drop Off Address"].toString(),
      customerRef: row["CustomerRef"].toString(),
      timeWindow: row["Time Window1"].toString(),
      orderAmount: row["Order Amount[Units]"].toString(),
      price: row["Price"].toString(),
      stocks: row["Storage Condition"]!.toString(),
      weight: row["Weight (kg)"].toString(),
      status: row["status"]?.toString() ?? "pending",
      date: DateTime.tryParse(row["Date"].toString()) ?? DateTime.now(),
      proof: null,
    );
  }

  /// ✅ Added copyWith
  Job2 copyWith({
    String? id,
    String? driverId,
    String? orderType,
    DateTime? dueDate,
    String? pickupLocation,
    LatLngPoint? pickupLatLng,
    String? dropoffLocation,
    LatLngPoint? dropoffLatLng,
    String? address,
    String? customerRef,
    String? timeWindow,
    String? orderAmount,
    String? price,
    String? stocks,
    String? weight,
    String? status,
    DateTime? date,
    Proof? proof,
  }) {
    return Job2(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      orderType: orderType ?? this.orderType,
      dueDate: dueDate ?? this.dueDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLatLng: pickupLatLng ?? this.pickupLatLng,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      dropoffLatLng: dropoffLatLng ?? this.dropoffLatLng,
      address: address ?? this.address,
      customerRef: customerRef ?? this.customerRef,
      timeWindow: timeWindow ?? this.timeWindow,
      orderAmount: orderAmount ?? this.orderAmount,
      price: price ?? this.price,
      stocks: stocks ?? this.stocks,
      weight: weight ?? this.weight,
      status: status ?? this.status,
      date: date ?? this.date,
      proof: proof ?? this.proof,
    );
  }
}