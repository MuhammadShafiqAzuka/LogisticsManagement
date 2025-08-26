import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logistic_management/features/developer/location_toggle_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/storage/local_storage.dart';
import '../../admin /presentations/admin_dashboard.dart';
import '../../driver/presentations/driver_dashboard.dart';
import '../provider/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _role = "driver"; // default role
  bool _isPasswordVisible = false;
  int _loginTapCount = 0; // for hidden developer access

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String _version = "";
  String _buildNumber = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();

    // Auto login if session exists
    Future.microtask(() async {
      if (await LocalStorage.isLoggedIn()) {
        final role = await LocalStorage.getRole();
        if (role == 'driver') {
          final driverId = await LocalStorage.getDriverId();
          _redirect(role, driverId: driverId);
        } else {
          _redirect(role);
        }
      }
    });
  }

  Future<void> _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _redirect(String? role, {String? driverId}) {
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (role == 'driver' && driverId != null && driverId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DriverDashboard(driverId: driverId)),
      );
    } else if (role == 'developer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationTogglePage()),
      );
    }
  }

  Future<void> _login() async {
    _loginTapCount++;

    // Hidden developer mode after 5 taps
    if (_loginTapCount >= 5) {
      _loginTapCount = 0; // reset counter after triggering
      _redirect('developer');
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    final user = await repo.login(_role, emailController.text, passwordController.text);

    if (user != null) {
      // Reset tap count on successful login
      _loginTapCount = 0;

      ref.read(authStateProvider.notifier).state = _role;

      if (_role == 'driver') {
        await LocalStorage.saveLogin(_role, driverId: user.id);
        _redirect(_role, driverId: user.id);
      } else {
        await LocalStorage.saveLogin(_role);
        _redirect(_role);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _role[0].toUpperCase() + _role.substring(1);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _role == "admin" ? Icons.admin_panel_settings : Icons.directions_bus,
                            size: 60,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$roleLabel Login",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "$roleLabel Email",
                              hintText: _role == "admin" ? "a1234" : "d1234",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Password",
                              hintText: _role == "admin" ? "admin123" : "driver123",
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _login,
                              child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Role Switcher (driver/admin only)
                          Wrap(
                            spacing: 12,
                            children: [
                              ChoiceChip(
                                label: const Text("Driver"),
                                selected: _role == "driver",
                                onSelected: (_) => setState(() => _role = "driver"),
                              ),
                              ChoiceChip(
                                label: const Text("Admin"),
                                selected: _role == "admin",
                                onSelected: (_) => setState(() => _role = "admin"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Version: $_version ($_buildNumber)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}