import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../driver/providers/driver_job_provider.dart';
import '../data/auth_repository.dart';
import '../../admin /provider/admin_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final driverRepo = ref.read(driverRepositoryProvider);
  final adminRepo = ref.read(adminRepositoryProvider);
  final developerRepo = ref.read(developerRepositoryProvider);

  return AuthRepository(driverRepo, adminRepo, developerRepo);
});

final authStateProvider = StateProvider<String?>((ref) => null);
