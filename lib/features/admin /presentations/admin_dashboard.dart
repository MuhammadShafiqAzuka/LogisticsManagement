import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logistic_management/core/widgets/all_driver_location_page.dart';
import 'package:logistic_management/core/widgets/job_map_page.dart';
import '../../../core/storage/local_storage.dart';
import '../../developer/location_toggle_page.dart';
import '../../auth/presentation/login_screen.dart';
import 'all_job_page.dart';
import 'all_drivers_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;
  final _pages = const [
    AllJobPage(),
    AllDriversPage(),

  ];
  ///AllStockPage(),
  ///BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stocks'),
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.location_history),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllDriversLiveLocationPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Drivers'),
        ],
      ),
    );
  }
}