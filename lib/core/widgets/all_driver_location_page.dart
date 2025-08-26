import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../features/admin /model/job.dart';
import '../../features/admin /provider/driver_notifer.dart';

class AllDriversLiveLocationPage extends ConsumerStatefulWidget {
  const AllDriversLiveLocationPage({super.key});

  @override
  ConsumerState<AllDriversLiveLocationPage> createState() => _AllDriversLiveLocationPageState();
}

class _AllDriversLiveLocationPageState extends ConsumerState<AllDriversLiveLocationPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Map<String, LatLngPoint>>? _driversLocationSub;
  final Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _listenAllDrivers();
  }

  @override
  void dispose() {
    _driversLocationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _listenAllDrivers() {
    final notifier = ref.read(driverNotifierProvider.notifier);

    _driversLocationSub = notifier.watchAllDriversLocations().listen((driversMap) {
      final newMarkers = <MarkerId, Marker>{};

      driversMap.forEach((driverId, point) {
        newMarkers[MarkerId(driverId)] = Marker(
          markerId: MarkerId(driverId),
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(title: "Driver: $driverId"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });

      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });

      // Fit all markers on the map
      _fitAllMarkers();
    });
  }

  void _fitAllMarkers() {
    if (_mapController == null || _markers.isEmpty) return;

    double minLat = _markers.values.first.position.latitude;
    double maxLat = minLat;
    double minLng = _markers.values.first.position.longitude;
    double maxLng = minLng;

    for (final marker in _markers.values) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = const LatLng(3.1390, 101.6869); // fallback

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Drivers Live Location"),
        automaticallyImplyLeading: true,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialPosition, zoom: 12),
        markers: Set<Marker>.of(_markers.values),
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
      ),
    );
  }
}