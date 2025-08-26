import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../developer/developer_repository.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final developerRepositoryProvider = Provider<DeveloperRepository>((ref) {
  return DeveloperRepository();();
});