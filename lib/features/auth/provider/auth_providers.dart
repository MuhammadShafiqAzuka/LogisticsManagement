import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Holds the role of the current user
final authRoleProvider = FutureProvider.family<String?, String>((ref, uid) async {
  final repo = ref.read(authRepositoryProvider);
  final role = await repo.getUserRole(uid);
  return role ?? "unknown";
});
