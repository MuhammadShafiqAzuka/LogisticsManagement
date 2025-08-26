import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../core/constants/const.dart';
import '../../../core/service/background_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/presentation/login_screen.dart';
import 'my_jobs_page.dart';

class DriverDashboard extends StatefulWidget {
  final String driverId;
  const DriverDashboard({super.key, required this.driverId});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _trackingControlSubscription;
  bool _trackingEnabled = false;

  @override
  void initState() {
    super.initState();
    _listenToAdminControl();
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _trackingControlSubscription?.cancel();
    super.dispose();
  }

  /// Listen to admin global switch
  void _listenToAdminControl() {
    _trackingControlSubscription =
        _database.child("settings/trackingEnabled").onValue.listen((event) {
          final enabled = event.snapshot.value == true;
          setState(() => _trackingEnabled = enabled);

          if (enabled) {
            _initLocationTracking();
          } else {
            _stopLocationTracking();
          }
        });
  }

  /// Initialize live location tracking (background service)
  Future<void> _initLocationTracking() async {
    bool permissionGranted = await checkAndRequestPermissions(isDriver: true);
    if (!permissionGranted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
                'Location permission is needed to track your live location.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Start background service with driverId
    await initializeService(widget.driverId);
  }

  /// Stop tracking service
  Future<void> _stopLocationTracking() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(
                Icons.location_on,
                color: _trackingEnabled ? Colors.green : Colors.grey,
                size: 24,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _stopLocationTracking();
              await LocalStorage.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: MyJobsPage(driverId: widget.driverId),
    );
  }
}
