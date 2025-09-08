import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../features/admin /model/job.dart';
import '../../features/admin /provider/driver_notifer.dart';
import '../../features/driver/providers/driver_job_provider.dart';
import '../constants/const.dart';

class AllDriversLiveLocationWithJobsPage extends ConsumerStatefulWidget {
  const AllDriversLiveLocationWithJobsPage({super.key});

  @override
  ConsumerState<AllDriversLiveLocationWithJobsPage> createState() => _AllDriversLiveLocationWithJobsPageState();
}

class _AllDriversLiveLocationWithJobsPageState extends ConsumerState<AllDriversLiveLocationWithJobsPage> {
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  final Map<String, List<Job2>> _currentJobsForDriver = {};

  StreamSubscription<Map<String, LatLngPoint>>? _driverLocationSub;
  final Map<String, StreamSubscription<List<Job2>>> _jobSubs = {};

  @override
  void initState() {
    super.initState();
    _listenDrivers();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _jobSubs.forEach((_, sub) => sub.cancel());
    _mapController?.dispose();
    super.dispose();
  }

  void _listenDrivers() {
    final driverNotifier = ref.read(driverNotifierProvider.notifier);
    final jobRepo = ref.read(job2RepositoryProvider);

    _driverLocationSub = driverNotifier.watchAllDriversLocations().listen(
          (driverLocations) {
        driverLocations.forEach((driverId, loc) {
          final markerId = MarkerId('driver_$driverId');

          // Driver marker
          _markers[markerId] = Marker(
            markerId: markerId,
            position: LatLng(loc.latitude, loc.longitude),
            infoWindow: InfoWindow(title: 'Driver: $driverId'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          );

          // Listen to active jobs
          if (!_jobSubs.containsKey(driverId)) {
            _jobSubs[driverId] = jobRepo.watchActiveDriverJobs(driverId).listen(
                  (activeJobs) => _updatePolylinesForDriver(driverId, loc, activeJobs),
            );
          } else {
            _updatePolylinesForDriver(driverId, loc, _currentJobsForDriver[driverId] ?? []);
          }
        });

        setState(() {});
      },
      onError: (e) => debugPrint('Error fetching driver locations: $e'),
    );
  }

  void _updatePolylinesForDriver(String driverId, LatLngPoint driverLoc, List<Job2> jobs) {
    _currentJobsForDriver[driverId] = jobs;

    final newPolylines = <PolylineId, Polyline>{};
    int i = 0;

    for (final job in jobs) {
      final polyId = PolylineId('poly_${driverId}_$i');
      final statusColors = statusStyle(job.status);
      final lineColor = (statusColors['text'] as Color?) ?? Colors.blue;

      newPolylines[polyId] = Polyline(
        polylineId: polyId,
        points: [
          LatLng(driverLoc.latitude, driverLoc.longitude),
          LatLng(job.dropoffLatLng.latitude, job.dropoffLatLng.longitude),
        ],
        color: lineColor,
        width: 4,
      );

      // Drop-off marker
      final dropMarkerId = MarkerId('drop_${driverId}_$i');
      _markers[dropMarkerId] = Marker(
        markerId: dropMarkerId,
        position: LatLng(job.dropoffLatLng.latitude, job.dropoffLatLng.longitude),
        infoWindow: InfoWindow(title: 'Job: ${job.id}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(_colorToHue(lineColor)),
      );

      i++;
    }

    _polylines.removeWhere((key, _) => key.value.startsWith('poly_$driverId'));
    _polylines.addAll(newPolylines);

    setState(() {});
    _fitAllMarkers();
  }

  double _colorToHue(Color color) => HSLColor.fromColor(color).hue;

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

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = const LatLng(3.1390, 101.6869);

    return Scaffold(
      appBar: AppBar(title: const Text('All Drivers Live Locations')),
      body: Column(
        children: [
          // Map on top
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initialPosition, zoom: 12),
              markers: Set<Marker>.of(_markers.values),
              polylines: Set<Polyline>.of(_polylines.values),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),

          // Driver + active jobs list at bottom
          Expanded(
            flex: 1,
            child: ListView(
              children: _currentJobsForDriver.entries.map((entry) {
                final driverId = entry.key;
                final jobs = entry.value;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    title: Text('Driver: $driverId'),
                    subtitle: Text('${jobs.length} active job(s)'),
                    children: jobs.map((job) {
                      final colors = statusStyle(job.status);
                      return ListTile(
                        title: Text('Job ID: ${job.id}'),
                        subtitle: Text('Status: ${job.status}'),
                        trailing: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors['text'] as Color?,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}