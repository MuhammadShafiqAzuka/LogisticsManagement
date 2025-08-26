import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as polyline_points;
import 'package:google_maps_flutter/google_maps_flutter.dart' as polyline_points;
import '../../features/admin /model/job.dart';
import '../../features/admin /provider/driver_notifer.dart';
import '../../features/driver/model/driver_job_status.dart';
import '../../features/driver/providers/driver_job_status_notifer.dart';
import '../constants/const.dart';
import 'package:timeline_tile/timeline_tile.dart';

class JobMapPage extends ConsumerStatefulWidget {
  final Job2 job;
  final bool showNavigation, isAdmin;
  const JobMapPage({
    super.key,
    required this.job,
    this.isAdmin = false,
    this.showNavigation = true,
  });

  @override
  ConsumerState<JobMapPage> createState() => _JobMapPageState();
}

class _JobMapPageState extends ConsumerState<JobMapPage> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _showAllStocks = false;
  StreamSubscription<LatLngPoint?>? _driverLocationSub;

  final Map<MarkerId, Marker> _markers = {};
  final Map<polyline_points.PolylineId, polyline_points.Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];
  late polyline_points.PolylinePoints _polylinePoints;
  LatLng? _lastLocation;

  bool _isLoading = false;
  String? _error;
  String? _distance;
  String? _duration;

  @override
  void initState() {
    super.initState();
    _polylinePoints = polyline_points.PolylinePoints(apiKey: apiKey);

    _addMarkers();
    _fetchRoute();
    if (widget.job.status == 'active') {
      _listenDriverLocation();
    }
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _addMarkers() {
    final pickupPos = LatLng(
      widget.job.pickupLatLng.latitude,
      widget.job.pickupLatLng.longitude,
    );
    final dropoffPos = LatLng(
      widget.job.dropoffLatLng.latitude,
      widget.job.dropoffLatLng.longitude,
    );

    _markers[const MarkerId('pickup')] = Marker(
      markerId: const MarkerId('pickup'),
      position: pickupPos,
      infoWindow: InfoWindow(title: widget.job.pickupLocation),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    _markers[const MarkerId('dropoff')] = Marker(
      markerId: const MarkerId('dropoff'),
      position: dropoffPos,
      infoWindow: InfoWindow(title: widget.job.dropoffLocation),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }

  String getFormattedDistance(polyline_points.Route route) {
    final distanceKm = route.distanceKm;
    return distanceKm != null ? '${distanceKm.toStringAsFixed(1)} km' : 'Unknown distance';
  }

  String getFormattedDuration(polyline_points.Route route) {
    final durationMin = route.durationMinutes;
    if (durationMin == null) return 'Unknown duration';

    final totalMinutes = durationMin.round();

    if (totalMinutes < 60) {
      return '$totalMinutes min${totalMinutes > 1 ? 's' : ''}';
    } else if (totalMinutes < 1440) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      if (mins == 0) {
        return '$hours hr${hours > 1 ? 's' : ''}';
      }
      return '$hours hr${hours > 1 ? 's' : ''} $mins min';
    } else {
      final days = totalMinutes ~/ 1440;
      final hours = (totalMinutes % 1440) ~/ 60;
      if (hours == 0) {
        return '$days day${days > 1 ? 's' : ''}';
      }
      return '$days day${days > 1 ? 's' : ''} $hours hr${hours > 1 ? 's' : ''}';
    }
  }

  Future<void> _fetchRoute() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _distance = null;
      _duration = null;
      _polylineCoordinates.clear();
      _polylines.clear();
    });

    final origin = polyline_points.PointLatLng(
      widget.job.pickupLatLng.latitude,
      widget.job.pickupLatLng.longitude,
    );
    final destination = polyline_points.PointLatLng(
      widget.job.dropoffLatLng.latitude,
      widget.job.dropoffLatLng.longitude,
    );

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinatesV2(
        request: polyline_points.RoutesApiRequest(
          origin: origin,
          destination: destination,
          travelMode: polyline_points.TravelMode.driving,
        ),
      );

      final route = result.primaryRoute;
      if (route != null && route.polylinePoints != null) {
        _polylineCoordinates.addAll(
          route.polylinePoints!.map((p) => LatLng(p.latitude, p.longitude)),
        );

        final polylineId = const polyline_points.PolylineId('route');
        final polyline = polyline_points.Polyline(
          polylineId: polylineId,
          color: Colors.blue.shade700,
          width: 6,
          points: _polylineCoordinates,
          patterns: [polyline_points.PatternItem.dash(15), polyline_points.PatternItem.gap(10)],
        );

        setState(() {
          _polylines[polylineId] = polyline;
          _distance = getFormattedDistance(route);
          _duration = getFormattedDuration(route);
        });

        _fitBounds();
      } else {
        setState(() {
          _error = result.errorMessage ?? 'No route found';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fitBounds() {
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

  void _listenDriverLocation() {
    final driverId = widget.job.driverId;
    final notifier = ref.read(driverNotifierProvider.notifier);

    _driverLocationSub = notifier.watchDriverLocation(driverId).listen((point) {
      if (point == null) return;

      final newPos = LatLng(point.latitude, point.longitude);

      setState(() {
        _lastLocation = newPos;
        _markers[const MarkerId('lastLocation')] = Marker(
          markerId: const MarkerId('lastLocation'),
          position: newPos,
          infoWindow: const InfoWindow(title: "Driver's Last Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = LatLng(
      widget.job.pickupLatLng.latitude,
      widget.job.pickupLatLng.longitude,
    );

    final stocks = widget.job.stocks;
    final isStockLong = stocks.length > 1;
    final jobUpdate = widget.job.status == 'active'
        ? ref.watch(jobStatusProvider.select((map) => map[widget.job.id]))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.id),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPosition, zoom: 14),
            markers: Set<Marker>.of(_markers.values),
            polylines: Set<Polyline>.of(_polylines.values),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // ✅ bottom sheet stays mostly same
          DraggableScrollableSheet(
            initialChildSize: 0.18,
            minChildSize: 0.18,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return _buildBottomSheet(context, scrollController, isStockLong, jobUpdate);
            },
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          if (_error != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $_error',
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, ScrollController scrollController, bool isStockLong, JobStatusUpdate? jobUpdate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Distance & Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoItem(icon: Icons.timeline, label: 'Distance', value: _distance ?? '--'),
              _InfoItem(icon: Icons.timer, label: 'Duration', value: _duration ?? '--'),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          _buildStopList(),

          const SizedBox(height: 16),
          const Divider(),

          Text("Stock Carried", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
            title: Text(widget.job.stocks),
          ),
          if (isStockLong)
            TextButton(
              onPressed: () => setState(() => _showAllStocks = !_showAllStocks),
              child: Text(_showAllStocks ? "Show Less" : "Show More", style: const TextStyle(color: Colors.blue)),
            ),

          if (widget.job.status == 'active') ...[
            const Divider(),

            if (widget.showNavigation)...[
              const SizedBox(height: 16),
              Text(
                "Navigation",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openGoogleMaps(context, widget.job.pickupLatLng.latitude, widget.job.pickupLatLng.longitude),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/google_map.png', // make sure you add the icon in assets
                              height: 40,
                            ),
                            const SizedBox(height: 4),
                            const Text("Google Maps", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => openWaze(context, widget.job.pickupLatLng.latitude, widget.job.pickupLatLng.longitude),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/waze.png', // make sure you add the icon in assets
                              height: 40,
                            ),
                            const SizedBox(height: 4),
                            const Text("Waze", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],

          if(!widget.showNavigation)...[

            if(widget.job.status == 'finished' && widget.isAdmin)...[
              const SizedBox(height: 16),
              const Divider(),
              Text(
                "Proof of Delivery",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildProofImage(jobUpdate?.proofPath ?? widget.job.proof?.proofPhoto, isLocal: widget.job.proof?.proofPhoto == null),
              const SizedBox(height: 12),
              Text(
                "Proof of Signature",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (jobUpdate?.signatureBytes != null)
                Image.memory(jobUpdate!.signatureBytes!, height: 150, fit: BoxFit.cover),
              if (widget.job.proof?.proofSignature != null)
                Image.asset(widget.job.proof!.proofSignature!, height: 150, fit: BoxFit.cover),
            ],

            if ((widget.job.status == 'returned' || widget.job.status == 'pending') && widget.isAdmin) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text(
                widget.job.status == 'returned'
                    ? "Reason for Returning"
                    : "Reason for Pending",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (widget.job.proof?.proofReason != null)
                Text(
                  "Reason: ${widget.job.proof?.proofReason ?? 'No reason provided'}",
                ),
              const SizedBox(height: 12),
              if (widget.job.proof?.proofPhoto != null)
                _buildProofImage(
                  widget.job.proof?.proofPhoto,
                  isLocal: widget.job.proof?.proofPhoto == null,
                ),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildProofImage(String? proofPath, {bool isLocal = false}) {
    if (proofPath == null) return const SizedBox();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.maxFinite,
        child: isLocal
            ? Image.file(
          File(proofPath),
          height: 150,
          fit: BoxFit.cover,
        )
            : Image.asset(
          proofPath,
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStopList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Stops", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Column(
          children: [
            TimelineTile(
              isFirst: true,
              alignment: TimelineAlign.start,
              lineXY: 0.1,
              indicatorStyle: IndicatorStyle(
                color: Colors.blue,
                width: 20,
                iconStyle: IconStyle(iconData: Icons.my_location, color: Colors.white),
              ),
              endChild: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.job.pickupLocation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              beforeLineStyle: LineStyle(color: Colors.grey.shade400, thickness: 2),
            ),
            TimelineTile(
              isLast: true,
              alignment: TimelineAlign.start,
              lineXY: 0.1,
              indicatorStyle: IndicatorStyle(
                color: Colors.red,
                width: 20,
                iconStyle: IconStyle(iconData: Icons.location_on, color: Colors.white),
              ),
              endChild: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.job.dropoffLocation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              beforeLineStyle: LineStyle(color: Colors.grey.shade400, thickness: 2),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Colors.blueGrey.shade700;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
