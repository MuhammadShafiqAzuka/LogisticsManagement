import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/storage/local_storage.dart';
import '../auth/presentation/login_screen.dart';

class LocationTogglePage extends StatefulWidget {
  const LocationTogglePage({super.key});

  @override
  State<LocationTogglePage> createState() => _LocationTogglePageState();
}

class _LocationTogglePageState extends State<LocationTogglePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _trackingEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenTrackingStatus();
  }

  /// Listen to current admin setting
  void _listenTrackingStatus() {
    _database.child("settings/trackingEnabled").onValue.listen((event) {
      final enabled = (event.snapshot.value ?? false) == true; // default to false
      setState(() {
        _trackingEnabled = enabled;
        _loading = false; // stop loading even if null
      });
    });
  }

  /// Update global setting
  Future<void> _updateTracking(bool value) async {
    await _database.child("settings/trackingEnabled").set(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Dashboard'),
      ),

      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : SwitchListTile(
          title: const Text("Enable Live Location for All Drivers"),
          subtitle: Text(
            _trackingEnabled
                ? "Drivers are currently sharing location"
                : "Drivers are NOT sharing location",
          ),
          value: _trackingEnabled,
          onChanged: (bool value) async {
            setState(() => _trackingEnabled = value);
            await _updateTracking(value);
          },
        ),
      ),
    );
  }
}