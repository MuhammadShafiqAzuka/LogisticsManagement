import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/const.dart';
import '../../../core/service/background_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/provider/auth_providers.dart';
import 'my_jobs_page.dart';
import 'profile_page.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  final String driverId;
  const DriverDashboard({super.key, required this.driverId});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MyJobsPage(driverId: widget.driverId),
      DriverProfilePage(),
    ];

    _initLocationTracking();
    _saveFcmToken();
  }

  /// Initialize background location service
  Future<void> _initLocationTracking() async {
    bool permissionGranted = await checkAndRequestPermissions(isDriver: true);
    if (!permissionGranted) return;

    await initializeService(widget.driverId);
  }

  /// Save FCM token to Firestore and listen for refreshes
  Future<void> _saveFcmToken() async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"fcmToken": token});
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"fcmToken": newToken});
      });
    } catch (e) {
      debugPrint("❌ Error saving FCM token: $e");
    }
  }

  /// Logout method using AuthRepository from Riverpod
  Future<void> _logout() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");

    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut(); // ✅ clears FCM token + signs out

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
        title: Text(_currentIndex == 0 ? 'My Jobs' : 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}