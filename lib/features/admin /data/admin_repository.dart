import '../model/admin.dart';

class AdminRepository {
  final _admins = [
    Admin(
      id: 'admin1',
      email: 'admin@test.com',
      passwordHash: 'admin',
    ),
  ];

  Future<List<Admin>> getAllAdmins() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _admins;
  }
}