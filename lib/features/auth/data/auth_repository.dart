import 'package:collection/collection.dart';
import '../../admin /data/admin_repository.dart';
import '../../admin /data/driver_repository.dart';
import '../../developer/developer_repository.dart';

class AuthRepository {
  final DriverRepository driverRepo;
  final AdminRepository adminRepo;
  final DeveloperRepository developerRepository;

  AuthRepository(this.driverRepo, this.adminRepo, this.developerRepository);

  /// Returns the logged-in Admin or Driver object, or null if not found.
  Future<dynamic> login(String role, String email, String passwordHash) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (role == 'admin') {
      final admins = await adminRepo.getAllAdmins();
      return admins.firstWhereOrNull(
            (a) => a.email == email && a.passwordHash == passwordHash,
      );
    }

    if (role == 'driver') {
      final drivers = await driverRepo.getAllDrivers();
      return drivers.firstWhereOrNull(
            (d) => d.email == email && d.passwordHash == passwordHash,
      );
    }

    if (role == 'developer') {
      final drivers = await developerRepository.getDeveloper();
      return drivers.firstWhereOrNull(
            (d) => d.email == email && d.passwordHash == passwordHash,
      );
    }
    return null;
  }
}
