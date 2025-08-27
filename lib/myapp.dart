import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'features/admin /presentations/admin_dashboard.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/provider/auth_providers.dart';
import 'features/developer/location_toggle_page.dart';
import 'features/driver/presentations/driver_dashboard.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current Firebase user
    final authUser = ref.watch(authRepositoryProvider).currentUser;

    // Use a FutureProvider to fetch the role whenever the user changes
    final authRoleAsync = authUser == null
        ? AsyncValue.data(null)
        : ref.watch(authRoleProvider(authUser.uid));

    return MaterialApp(
      home: authRoleAsync.when(
        data: (role) {
          if (authUser == null || role == null) {
            return const LoginScreen();
          }

          switch (role) {
            case "admin":
              return const AdminDashboard();
            case "driver":
              return DriverDashboard(driverId: authUser.uid);
            case "developer":
              return const LocationTogglePage();
            default:
              return const LoginScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text("Error: $e")),
        ),
      ),
    );
  }
}