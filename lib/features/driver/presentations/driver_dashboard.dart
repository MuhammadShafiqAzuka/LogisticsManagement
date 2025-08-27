import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../../core/service/background_service.dart';
import '../../auth/presentation/login_screen.dart';
import 'my_jobs_page.dart';
import '../../../core/constants/const.dart';

class DriverDashboard extends StatefulWidget {
  final String driverId;
  const DriverDashboard({super.key, required this.driverId});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    bool permissionGranted = await checkAndRequestPermissions(isDriver: true);
    if (!permissionGranted) return;

    await initializeService(widget.driverId);
  }

  Future<void> _logout() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: MyJobsPage(driverId: widget.driverId),
    );
  }
}